local mn = "sloptech";

core.register_node(mn .. ':test_machine', {
    description = "Test machine\nDoes nothing\nVoltage in: 8 EU/t (ULV)\nEnergy capacity: 1,024 EU",
    tiles = { mn .. '_blocks.casings.ulv.png' },
    groups = {
        cracky = 1,
        [mn .. ':' .. 'machine'] = 1
    }
})
