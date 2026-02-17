core.register_tool("sloptech:test_wrench", {
    description = "Test Wrench\nFe₄S₂A₀\nFire, hello world", --208N
    inventory_image = "sloptech_items.test_wrench.png",
    on_place = function(item, _p, pointedThing)
        if pointedThing.type == "node" then
            sloptech.wrenchUse(pointedThing.under, pointedThing.above);
        end
        return nil
    end
})
