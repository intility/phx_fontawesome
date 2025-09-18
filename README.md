<div align="center">
  <img src="assets/logo.png" height="128">
  <h1 align="center">PhxFontawesome</h1>
</div>

![pipeline status](https://github.com/Intility/phx_fontawesome/actions/workflows/elixir.yml/badge.svg?event=push)

> [!WARNING]
> This project is discontinued due to no longer being used in any active project.
> Please reach out if you wish to take over maintainance. 

## About

A simple Mix task that generates Phoenix Components from Font Awesome SVG files. Documentation is available
[here](https://hexdocs.pm/phx_fontawesome).

## Installation

This package is [available in Hex](https://hex.pm/packages/phx_fontawesome), and can be installed
by adding `phx_fontawesome` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phx_fontawesome, "~> 1.2"}
  ]
end
```

## Generate Heex components

**Step 1 - Install desired font set**

Install desired font set. Please consult the Font Awesome
[documentation](https://fontawesome.com/docs/web/setup/packages) if you run into any trouble here.

```shell
$ cd assets/
$ npm install --prefix assets @fortawesome/fontawesome-free
# or
$ npm install --prefix assets  @fortawesome/fontawesome-pro     # needs a license
```

**Step 2 - Choose font set types to generate**

In your `config.exs`, you may choose which types to generate `heex` components for. Defaults to `regular` and `solid`.

```elixir
config :phx_fontawesome,
  types: ["regular", "solid"]
```

Additionally, you may override the default location for generated files (`deps/phx_fontawesome/lib`).

```elixir
config :phx_fontawesome,
  dest_path: "./lib/phx_fontawesome"  # includes generated files in your projects lib/ directory
```

**Step 3 - Generate component files**

From your project root, run `mix phx_fontawesome.generate` to create components files. Generated components will be available in your
`deps/phx_fontawesome/lib/phx_fontawesome` directory (unless using a custom path).

```shell
$ mix phx_fontawesome.generate
[info]  Successfully wrote /my_project/deps/phx_fontawesome/lib/phx_fontawesome/fontawesome_free/regular.ex (containing 162 SVG components).
[info]  Successfully wrote /my_project/deps/phx_fontawesome/lib/phx_fontawesome/fontawesome_free/solid.ex (containing 1385 SVG components).
$ mix deps.compile phx_fontawesome
==> phx_fontawesome
Compiling 3 files (.ex)
...
```

**Remember to run `mix deps.compile phx_fontawesome` after generating files to compile the components!**

## Usage

If using the default `dest_path`, you need to add `deps/phx_fontawesome/lib/phx_fontawesome` to your `elixirc_paths`.

```elixir
# mix.exs
defmodule MyProject.MixProject do

  # snip...

  defp elixirc_paths(_env) do
    [
      "lib",
      "test/support",
      "deps/phx_fontawesome/lib/phx_fontawesome"  # add this line
    ]
  end
end
```

Once generated, the `heex` components are available to your project, and can be used as a regular `Phoenix.Component`.
Icon name can be the function or passed in as a type.

```html
<!-- Use the PhxFontawesome component and pass all required props -->
<PhxFontawesome.render icon="angle_up" set="free" type="regular" />

<!-- Or use the generated components directly -->
<PhxFontawesome.Free.Solid.angle_up />
<PhxFontawesome.Free.Regular.render icon="angle_up" />

<!-- append custom classes  -->
<PhxFontawesome.Free.Solid.angle_up class="my-custom-class" />

<!-- remove default classes by prefixing wiht "!"  -->
<PhxFontawesome.Free.Solid.angle_up class="!fa-angle-up" />

<!-- pass extra properties -->
<PhxFontawesome.Free.Solid.angle_up title="Font Awesome angle-up icon" />
```

If you would like to apply the default styling for SVG elements, simply include the Font Awesome CSS in your `app.css` file.

```css
@import "@fortawesome/fontawesome-free/css/all.css";
@import "@fortawesome/fontawesome-free/css/svg-with-js.css";
```

Keep in mind that if you're using the non-free version of Font Awesome, make sure that you don't publish the
generated components as that would be a licensing breach.

### Credits

- Component generator inspired by the [Petal Components](https://github.com/petalframework/petal_components) project.
- Logo comes from the [Font Awesome](https://commons.wikimedia.org/wiki/File:Font_Awesome_5_brands_phoenix-framework.svg) project.
