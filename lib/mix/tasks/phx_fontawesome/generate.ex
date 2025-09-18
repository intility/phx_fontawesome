defmodule Mix.Tasks.PhxFontawesome.Generate do
  @moduledoc false
  use Mix.Task
  require Logger

  @fontsets ~w(fontawesome-free fontawesome-pro)
  @src_path "./assets/node_modules/@fortawesome"
  @dest_path "./deps/phx_fontawesome/lib/phx_fontawesome"

  @shortdoc "Convert source SVG files into Phoenix components."
  def run(_) do
    sets = Application.get_env(:phx_fontawesome, :types) || ["regular", "solid"]
    {:ok, _pid} = Task.Supervisor.start_link(name: PhxFontawesome.TaskSupervisor)

    with {:ok, name} <- File.ls(@src_path),
         name <- Enum.filter(name, &Enum.member?(@fontsets, &1)),
         fontsets <- Enum.zip(name, Enum.map(name, &list_fontsets(&1, sets))) do
      Enum.map(fontsets, fn {namespace, fontset} ->
        build_context_module(namespace)

        Enum.map(fontset, fn f ->
          Task.Supervisor.async(PhxFontawesome.TaskSupervisor, fn ->
            build_module(namespace, f)
          end)
        end)
        |> Task.await_many(:infinity)
      end)
    else
      {:error, :enoent} ->
        Logger.error(
          "Directory #{Path.absname(@src_path)} does not exist.\n" <>
            "Please install desired font set using ie. 'npm install @fortawesome/fontawesome-free' " <>
            "from the assets directory."
        )
    end

    Mix.Task.run("format")
  end

  @spec list_fontsets(directory :: String.t(), sets :: [String.t()]) ::
          [{String.t(), [String.t()]}] | {:error, :enoent}
  defp list_fontsets(directory, sets) do
    with {:ok, can_process} <- File.ls(Path.join([@src_path, directory, "svgs"])),
         {:ok, to_process} <- intersect(can_process, sets),
         to_process_paths <- Enum.map(to_process, &Path.join([@src_path, directory, "svgs", &1])),
         fontset_files <- Enum.map(to_process_paths, &list_directory/1) do
      fontset_files
    else
      {:error, :enoent} = reply ->
        Logger.error(
          "Could not find directory #{Path.join(Path.absname(Path.join(@src_path, directory)), "svgs")}.\n" <>
            "Please make sure that the #{directory} fonts are properly installed."
        )

        reply
    end
  end

  defp fontset_name(fontset), do: String.capitalize(Path.basename(fontset))

  @spec list_directory(directory :: String.t()) :: {String.t(), [String.t()]}
  defp list_directory(directory) do
    files =
      File.ls!(directory)
      |> Enum.filter(&(Path.extname(&1) == ".svg"))
      |> Enum.sort()

    {directory, files}
  end

  @spec intersect([String.t()], [String.t()]) :: [String.t()]
  defp intersect(a, b),
    do: {:ok, MapSet.new(a) |> MapSet.intersection(MapSet.new(b)) |> MapSet.to_list()}

  @spec build_module(String.t(), {String.t(), [String.t()]}) :: :ok
  defp build_module(namespace, {fontset, files}) when is_list(files) do
    module_name =
      with namespace_name <- namespace_name(namespace),
           fontset_name <- fontset_name(fontset),
           do: "Phx#{namespace_name}.#{fontset_name}"

    file = """
    defmodule #{module_name} do
      @moduledoc \"\"\"
      Icon name can be the function or passed in as a type.

      ## Example

          <PhxFontawesome.#{fontset_name(fontset)}.Solid.angle_up />
          <PhxFontawesome.#{fontset_name(fontset)}.Regular.render icon="angle_up" />

          <!-- override default classes  -->
          <PhxFontawesome.#{fontset_name(fontset)}.Solid.angle_up class="my-custom-class" />

          <!-- pass extra properties -->
          <PhxFontawesome.#{fontset_name(fontset)}.Solid.angle_up title="Font Awesome angle-up icon" />

      \"\"\"
      use Phoenix.Component
      import PhxComponentHelpers, only: [extend_class: 3]

      def render(%{icon: icon_name} = assigns) when is_atom(icon_name) do
        apply(__MODULE__, icon_name, [assigns])
      end

      def render(%{icon: icon_name} = assigns) do
        icon_name = String.to_existing_atom(icon_name)
        apply(__MODULE__, icon_name, [assigns])
      end

    """

    dest_path = Path.join([dest_path(), String.replace(namespace, "-", "_")])
    dest_file = Path.join(dest_path, "#{Path.basename(fontset)}.ex")

    if !File.exists?(dest_path), do: File.mkdir_p!(dest_path)
    if File.exists?(dest_file), do: File.rm!(dest_file)

    output_stream = File.stream!(dest_file, [:utf8, :delayed_write, :append], :line)

    # Write beginning of file to output stream
    Stream.run(Stream.into([file], output_stream))

    # Write all functions to output stream
    response =
      Enum.map(files, &Path.join(fontset, &1))
      |> Task.async_stream(&stream_file/1)
      |> Enum.map(fn {:ok, %{enum: %{path: path}} = stream} ->
        IO.puts(IO.ANSI.format([:green, "Processing #{path}"]))
        Stream.run(Stream.into(stream, output_stream))
      end)

    # Write the final "end" statement to output stream
    Stream.run(Stream.into(["\nend"], output_stream))

    Logger.info(
      "Successfully wrote #{Path.absname(dest_file)} (containing #{length(response)} SVG components). "
    )
  end

  @spec build_function(String.t(), String.t()) :: String.t()
  defp build_function(svg_data, name) do
    """
      @doc \"\"\"
      Renders a Font Awesome
      [#{String.replace(name, "_", "-")}](https://fontawesome.com/search?q=#{String.replace(name, "_", "-")}) SVG icon.

      ## Props

        * `class` - `:string` - CSS class applied to the SVG element.
          - Default value: `svg-inline--fa fa-fw #{class_for(name)}`
          - Override default values by prefixing the class with `!`, ie. `class="!fa-fw my-custom-class"`
        * `rest` - properties - Any prop except `:class` that should be applied to the SVG element.
          - Example: `title=\"tooltip-title\"`

      Renders to default slot.
      \"\"\"
      def #{name}(assigns) do
        assigns =
          assigns
          |> extend_class("svg-inline--fa fa-fw #{class_for(name)}", prefix_replace: false)
          |> assign_new(:rest, fn -> assigns_to_attributes(assigns, ~w(class heex_class)a) end)

        ~H\"\"\"
        #{svg_data}
        \"\"\"
      end

    """
  end

  @spec build_context_module(String.t()) :: String.t()
  defp build_context_module(namespace) do
    module_name = namespace_name(namespace)

    file = """
    defmodule Phx#{module_name} do
      @moduledoc \"\"\"
      You can use this module to check if a specific font is available.
      Maybe you want to alias the font set to just Fontawesome.

          defmodule MyFontawesome do
            defmacro __using__(_) do
              quote do
                alias Phx#{module_name}, as: Fontawesome
              end
            end
          end


      And in your Phoenix components:

          defmodule MyComponent do
            use MyFontawesome

            ...
          end

      \"\"\"
    end
    """

    dest_path = Path.join([dest_path(), String.replace(namespace, "-", "_")])
    dest_file = "#{dest_path}.ex"
    if !File.exists?(dest_path()), do: File.mkdir_p!(dest_path())
    if File.exists?(dest_file), do: File.rm!(dest_file)

    output_stream = File.stream!(dest_file, [:utf8], :line)
    Stream.run(Stream.into([file], output_stream))
  end

  @spec dest_path() :: String.t()
  defp dest_path, do: Application.get_env(:phx_fontawesome, :dest_path) || @dest_path

  @spec namespace_name(String.t()) :: String.t()
  defp namespace_name(namespace),
    do: String.split(namespace, "-") |> Enum.map(&String.capitalize/1) |> Enum.join(".")

  @spec function_name(String.t()) :: String.t()
  defp function_name(name) do
    Path.basename(name, ".svg")
    |> String.replace("-", "_")
    |> ensure_valid_function_name()
  end

  @spec class_for(String.t()) :: String.t()
  defp class_for("zero"), do: "fa-0"
  defp class_for("one"), do: "fa-1"
  defp class_for("two"), do: "fa-2"
  defp class_for("three"), do: "fa-3"
  defp class_for("four"), do: "fa-4"
  defp class_for("five"), do: "fa-5"
  defp class_for("six"), do: "fa-6"
  defp class_for("seven"), do: "fa-7"
  defp class_for("eight"), do: "fa-8"
  defp class_for("nine"), do: "fa-9"
  defp class_for("double_zero"), do: "fa-00"
  defp class_for("eleven_ty"), do: "fa-11ty"
  defp class_for("fourty_two_group"), do: "fa-42-group"
  defp class_for("one_hundred"), do: "fa-100"
  defp class_for("five_hundred_px"), do: "fa-500px"
  defp class_for("three_sixty_degrees"), do: "fa-360-degrees"
  defp class_for(name), do: "fa-#{String.replace(name, "_", "-")}"

  @spec ensure_valid_function_name(String.t()) :: String.t()
  defp ensure_valid_function_name("00"), do: "double_zero"
  defp ensure_valid_function_name("0"), do: "zero"
  defp ensure_valid_function_name("1"), do: "one"
  defp ensure_valid_function_name("2"), do: "two"
  defp ensure_valid_function_name("3"), do: "three"
  defp ensure_valid_function_name("4"), do: "four"
  defp ensure_valid_function_name("5"), do: "five"
  defp ensure_valid_function_name("6"), do: "six"
  defp ensure_valid_function_name("7"), do: "seven"
  defp ensure_valid_function_name("8"), do: "eight"
  defp ensure_valid_function_name("9"), do: "nine"
  defp ensure_valid_function_name("11ty"), do: "eleven_ty"
  defp ensure_valid_function_name("42_group"), do: "fourty_two_group"
  defp ensure_valid_function_name("100"), do: "one_hundred"
  defp ensure_valid_function_name("500px"), do: "five_hundred_px"
  defp ensure_valid_function_name("360_degrees"), do: "three_sixty_degrees"
  defp ensure_valid_function_name(name), do: name

  @spec stream_file(String.t()) :: Stream.t()
  defp stream_file(file_path) do
    File.stream!(file_path)
    |> Stream.map(&String.trim/1)
    |> Stream.map(
      &String.replace(&1, ~r/<svg /, "<svg {@heex_class} {@rest} fill=\"currentColor\" ")
    )
    |> Stream.map(&String.replace(&1, ~r/<path/, "  <path"))
    |> Stream.map(&build_function(&1, function_name(file_path)))
  end
end
