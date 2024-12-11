defmodule PhxFontawesome.FreeTest do
  use ComponentCase

  test "can render fontawesome-free solid icon with current color correctly" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <PhxFontawesome.Free.Solid.basketball />
      """)

    assert html =~ "<svg class="
    assert html =~ "currentColor"
  end

  test "can render fontawesome-free solid icon with current color correctly via render component" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <PhxFontawesome.Free.Solid.render icon="basketball" />
      """)

    assert html =~ "<svg class="
    assert html =~ "currentColor"

    html =
      rendered_to_string(~H"""
      <PhxFontawesome.Free.Solid.render icon={:basketball} />
      """)

    assert html =~ "<svg class="
    assert html =~ "currentColor"
  end

  test "can render fontawesome-free regular icon with current color correctly" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <PhxFontawesome.Free.Regular.user />
      """)

    assert html =~ "<svg class="
    assert html =~ "currentColor"
  end

  test "can render fontawesome-free regular icon with current color correctly via render component" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <PhxFontawesome.Free.Regular.render icon="user" />
      """)

    assert html =~ "<svg class="
    assert html =~ "currentColor"

    html =
      rendered_to_string(~H"""
      <PhxFontawesome.Free.Regular.render icon={:user} />
      """)

    assert html =~ "<svg class="
    assert html =~ "currentColor"
  end

  test "can render fontawesome-free regular icon by type via render component" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <PhxFontawesome.render icon="user" set="free" type="regular" />
      """)

    assert html =~ "<svg class="
    assert html =~ "set=\"free\" type=\"regular\" icon=\"user\""
  end

  test "raises error when trying to render a non-existing icon" do
    assigns = %{}

    assert_raise FunctionClauseError,
                 "no function clause matching in PhxFontawesome.render/1",
                 fn ->
                   rendered_to_string(~H"""
                   <PhxFontawesome.render icon="user", set="invalid" type="regular" />
                   """)
                 end

    assert_raise ArgumentError,
                 "could not load module PhxFontawesome.Pro.Regular due to reason :nofile",
                 fn ->
                   rendered_to_string(~H"""
                   <PhxFontawesome.render icon="user", set="pro" type="regular" />
                   """)
                 end
  end

  test "can forward extra params to the underlying svg element" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <PhxFontawesome.Free.Regular.user zoid="berg" />
      """)

    assert html =~ "zoid"
    assert html =~ "berg"
  end

  test "can set custom css classes" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <PhxFontawesome.Free.Regular.user class="my-custom-class" />
      """)

    assert html =~ "fa-user my-custom-class"
  end

  test "can unset default css classes" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <PhxFontawesome.Free.Regular.user class="!fa-user my-custom-class" />
      """)

    assert html =~ "my-custom-class"
    refute html =~ "fa-user"
  end
end
