-- =======================================================
-- ANİMASYONLAR VE EĞRİLER
-- =======================================================

-- Bezier eğrileri
hl.curve("outfoxxedExpressive", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("emphasizedDecel",     { type = "bezier", points = { {0.05, 0.7}, {0.1, 1}    } })
hl.curve("emphasizedAccel",     { type = "bezier", points = { {0.3, 0},    {0.8, 0.15} } })
hl.curve("menuDecel",           { type = "bezier", points = { {0.1, 1},    {0, 1}      } })
hl.curve("menuAccel",           { type = "bezier", points = { {0.52, 0.03},{0.72, 0.08}} })

-- Animasyonlar
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 5,    bezier = "outfoxxedExpressive", style = "popin 80%"  })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 3,    bezier = "emphasizedDecel",     style = "popin 90%"  })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 5,    bezier = "outfoxxedExpressive", style = "slide"     })
hl.animation({ leaf = "border",           enabled = true, speed = 10,   bezier = "emphasizedDecel"                        })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 2.7,  bezier = "emphasizedDecel",     style = "popin 93%"  })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 2.4,  bezier = "menuAccel",          style = "popin 94%"  })
hl.animation({ leaf = "fadeLayersIn",     enabled = true, speed = 0.5,  bezier = "menuDecel"                              })
hl.animation({ leaf = "fadeLayersOut",    enabled = true, speed = 2.7,  bezier = "menuAccel"                             })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 6,    bezier = "outfoxxedExpressive", style = "slide"     })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 2.8,  bezier = "emphasizedDecel", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 1.2,  bezier = "emphasizedAccel", style = "slidevert" })
