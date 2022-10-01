local styles = data.raw["gui-style"].default

styles["ss_undock_button"] = {
    type = "button_style",
    parent = "green_button",
    horizontal_align = "left",
    tooltip = "space-spidertron-dock.undock-tooltip"
}

styles["ss_invisible_frame"] = {
    type = "frame_style",
    parent = "invisible_frame",
    horizontal_flow_style = {
        type = "horizontal_flow_style",
        horizontal_spacing = 20,
        horizontal_align = "right",
        horizontally_stretchable = "on",
        top_padding = 0,
        right_padding = 0,
    },
    vertical_flow_style = {
        type = "vertical_flow_style",
        vertical_spacing = 0,
        horizontal_align = "right",
        horizontally_stretchable = "on",
        top_padding = 0,
        right_padding = 0,
    },
}