Config = {}

Config.Debug = false

Config.peds = {
    ['survive'] = {
        'a_m_m_tramp_01',
        's_m_y_dealer_01',
        's_m_y_blackops_02',
        'g_m_y_ballaeast_01',
        'g_m_y_famca_01',
        'g_m_y_mexgoon_01'
    }
}

Config.pedmodel = {            --- dificuldade
    [1] = 'a_m_m_tramp_01',    -- mendigo
    [2] = 's_m_y_dealer_01',   -- traficante
    [3] = 's_m_y_blackops_02', -- militar
}

Config.policepeds = {
    [1] = 'g_m_y_ballaeast_01', -- ballas
    [2] = 'g_m_y_famca_01',     -- familie
    [3] = 'g_m_y_mexgoon_01',   -- latin
}

Config.pedsloot = {

    -- pednormais
    [`a_m_m_tramp_01`] = { -- a_m_m_tramp_01 (lvl1)
        { item = 'lockpick',    quant = 1 },
        { item = 'black_money', quant = 80 },
        { item = 'black_money', quant = 150 },
        { item = 'black_money', quant = 350 },
        { item = 'black_money', quant = 100 },
        { item = 'black_money', quant = 150 },
        { item = 'black_money', quant = 350 },
        { item = 'black_money', quant = 150 },
        { item = 'black_money', quant = 250 },
        { item = 'black_money', quant = 450 },
    },
    [`s_m_y_dealer_01`] = { -- s_m_y_dealer_01 (lvl2)
        { item = 'lockpick',    quant = 4 },
        { item = 'black_money', quant = 550 },
        { item = 'black_money', quant = 750 },
        { item = 'black_money', quant = 1050 },
        { item = 'black_money', quant = 550 },
        { item = 'black_money', quant = 750 },
        { item = 'black_money', quant = 1050 },
        { item = 'black_money', quant = 550 },
        { item = 'black_money', quant = 750 },
        { item = 'black_money', quant = 1050 },
    },
    [`s_m_y_blackops_02`] = { -- s_m_y_blackops_02 (lvl3)
        { item = 'bandage',     quant = 1 },
        { item = 'black_money', quant = 3050 },
    },

    -- ped_police
    [`g_m_y_ballaeast_01`] = { -- g_m_y_ballaeast_01 (lvl1)
        { item = 'bandage', quant = 1 },
    },
    [`g_m_y_famca_01`] = { -- g_m_y_famca_01 (lvl2)
        { item = 'bandage', quant = 1 },
    },
    [`g_m_y_mexgoon_01`] = { -- g_m_y_mexgoon_01 (lvl3)
        { item = 'bandage', quant = 1 },
    },
}

Config.weapon = { --- dificuldade
    [1] = `WEAPON_BOTTLE`,
    [2] = `weapon_pistol_mk2`,
    [3] = `weapon_smg`,
}

Config.vida = {
    [1] = 200,
    [2] = 180,
    [3] = 220,
}

Config.armour = {
    [1] = nil,
    [2] = 100,
    [3] = 100,
}

Config.quantloots = 1

Config.TimeToResetPed = 20 * 60

Config.spawnlocation = {

    ['Mendigo_vanilla1'] = {
        label = 'Mendigo_vanilla1',
        dificuldade = 1,
        quantidade = 3,
        policequest = false,
        radius = 50,
        coords = vec3(127.55, -1184.69, 29.5),
        coords_ped = {
            vec3(137.39, -1183.93, 29.76),
            vec3(123.92, -1184.61, 29.5),
            vec3(129.55, -1197.71, 29.51),
        },
    },

    ['Praça1'] = {
        label = 'Praça1',
        dificuldade = 1,
        quantidade = 8,
        policequest = false,
        radius = 200,
        coords = vec3(164.2, -978.15, 30.09),
        coords_ped = {
            vec3(194.65, -981.22, 30.09),
            vec3(199.94, -978.73, 30.09),
            vec3(198.74, -968.72, 30.09),
            vec3(165.72, -957.09, 30.09),
            vec3(162.97, -967.88, 30.09),
        },
    },

    -- ['Burgershot'] = {
    --     label = 'Burgershot',
    --     dificuldade = 1,
    --     quantidade = 1,
    --     policequest = false,
    --     radius = 100,
    --     coords = vec3(-1167.48, -882.88, 14.16),
    --     coords_ped = {
    --         vec3(-1167.48, -882.88, 14.16),
    --         vec3(-1177.02, -902.72, 13.62)
    --     },
    -- },
}
