extends RefCounted

const TEAMS: Array = [
	# Group A
	{"name": "Qatar",        "abbr": "QAT", "color": Color(0.49,  0.08,  0.22),  "accent": Color(1,    1,     1),
		"flag": {"type": "v_stripes", "colors": [Color(1,1,1), Color(0.49,0.08,0.22)]}},
	{"name": "Ecuador",      "abbr": "ECU", "color": Color(1,     0.82,  0),      "accent": Color(0,    0.38,  0.16),
		"flag": {"type": "h_stripes", "colors": [Color(1,0.82,0), Color(0,0.27,0.67), Color(0.76,0.08,0.08)]}},
	{"name": "Senegal",      "abbr": "SEN", "color": Color(0.02,  0.55,  0.22),   "accent": Color(0.95, 0.82,  0),
		"flag": {"type": "v_stripes", "colors": [Color(0.02,0.55,0.22), Color(1,0.82,0), Color(0.76,0.08,0.08)]}},
	{"name": "Netherlands",  "abbr": "NED", "color": Color(1,     0.427, 0),      "accent": Color(1,    1,     1),
		"flag": {"type": "h_stripes", "colors": [Color(0.69,0.07,0.17), Color(1,1,1), Color(0.07,0.24,0.56)]}},
	# Group B
	{"name": "England",      "abbr": "ENG", "color": Color(0.88,  0.88,  0.9),    "accent": Color(0.81, 0.08,  0.17),
		"flag": {"type": "england", "c1": Color(1,1,1), "c2": Color(0.76,0.08,0.08)}},
	{"name": "Iran",         "abbr": "IRN", "color": Color(0.18,  0.55,  0.22),   "accent": Color(1,    1,     1),
		"flag": {"type": "h_stripes", "colors": [Color(0.18,0.55,0.22), Color(1,1,1), Color(0.76,0.08,0.08)]}},
	{"name": "USA",          "abbr": "USA", "color": Color(0,     0.165, 0.416),  "accent": Color(0.75, 0.04,  0.19),
		"flag": {"type": "canton_stripes", "c1": Color(0.7,0.07,0.17), "c2": Color(1,1,1), "c3": Color(0,0.17,0.42)}},
	{"name": "Wales",        "abbr": "WAL", "color": Color(0.76,  0.08,  0.08),   "accent": Color(0,    0.4,   0.15),
		"flag": {"type": "wales", "c2": Color(0,0.4,0.15), "c3": Color(0.76,0.08,0.08)}},
	# Group C
	{"name": "Argentina",    "abbr": "ARG", "color": Color(0.45,  0.675, 0.875),  "accent": Color(1,    1,     1),
		"flag": {"type": "argentina", "colors": [Color(0.45,0.675,0.875), Color(1,1,1), Color(0.45,0.675,0.875)], "c2": Color(0.88,0.72,0), "c3": Color(0.78,0.52,0.02)}},
	{"name": "Saudi Arabia", "abbr": "KSA", "color": Color(0,     0.5,   0.12),   "accent": Color(1,    1,     1),
		"flag": {"type": "solid", "c1": Color(0,0.5,0.12)}},
	{"name": "Mexico",       "abbr": "MEX", "color": Color(0,     0.42,  0.18),   "accent": Color(0.82, 0.07,  0.12),
		"flag": {"type": "v_stripes", "colors": [Color(0,0.42,0.18), Color(1,1,1), Color(0.76,0.08,0.08)]}},
	{"name": "Poland",       "abbr": "POL", "color": Color(0.95,  0.05,  0.15),   "accent": Color(1,    1,     1),
		"flag": {"type": "h_stripes", "colors": [Color(1,1,1), Color(0.76,0.08,0.08)]}},
	# Group D
	{"name": "France",       "abbr": "FRA", "color": Color(0,     0.137, 0.584),  "accent": Color(0.93, 0.16,  0.22),
		"flag": {"type": "v_stripes", "colors": [Color(0,0.137,0.584), Color(1,1,1), Color(0.76,0.08,0.08)]}},
	{"name": "Australia",    "abbr": "AUS", "color": Color(1,     0.714, 0.071),  "accent": Color(0,    0.514, 0.239),
		"flag": {"type": "australia", "c1": Color(0,0.2,0.6), "c2": Color(0.76,0.08,0.08)}},
	{"name": "Denmark",      "abbr": "DEN", "color": Color(0.87,  0.06,  0.12),   "accent": Color(1,    1,     1),
		"flag": {"type": "nordic_cross", "c1": Color(0.87,0.06,0.12), "c2": Color(1,1,1)}},
	{"name": "Tunisia",      "abbr": "TUN", "color": Color(0.9,   0.9,   0.88),   "accent": Color(0.82, 0.1,   0.1),
		"flag": {"type": "circle", "c1": Color(0.82,0.1,0.1), "c2": Color(1,1,1)}},
	# Group E
	{"name": "Spain",        "abbr": "ESP", "color": Color(0.67,  0.08,  0.11),   "accent": Color(0.95, 0.75,  0),
		"flag": {"type": "h_stripes", "colors": [Color(0.67,0.08,0.11), Color(0.95,0.75,0), Color(0.67,0.08,0.11)]}},
	{"name": "Costa Rica",   "abbr": "CRC", "color": Color(0,     0.24,  0.65),   "accent": Color(0.82, 0.1,   0.1),
		"flag": {"type": "h_stripes", "colors": [Color(0,0.24,0.65), Color(1,1,1), Color(0.82,0.1,0.1), Color(1,1,1), Color(0,0.24,0.65)]}},
	{"name": "Germany",      "abbr": "GER", "color": Color(0.12,  0.12,  0.12),   "accent": Color(0.87, 0,     0),
		"flag": {"type": "h_stripes", "colors": [Color(0.1,0.1,0.1), Color(0.76,0.08,0.08), Color(0.95,0.75,0)]}},
	{"name": "Japan",        "abbr": "JPN", "color": Color(0.737, 0,     0.176),  "accent": Color(1,    1,     1),
		"flag": {"type": "circle", "c1": Color(1,1,1), "c2": Color(0.76,0.08,0.08)}},
	# Group F
	{"name": "Belgium",      "abbr": "BEL", "color": Color(0.04,  0.04,  0.2),    "accent": Color(0.94, 0.82,  0),
		"flag": {"type": "v_stripes", "colors": [Color(0.07,0.07,0.07), Color(0.94,0.82,0), Color(0.76,0.08,0.08)]}},
	{"name": "Canada",       "abbr": "CAN", "color": Color(0.86,  0.06,  0.06),   "accent": Color(1,    1,     1),
		"flag": {"type": "canada", "colors": [Color(0.86,0.06,0.06), Color(1,1,1), Color(0.86,0.06,0.06)], "c2": Color(0.86,0.06,0.06)}},
	{"name": "Morocco",      "abbr": "MAR", "color": Color(0.76,  0.09,  0.09),   "accent": Color(0,    0.388, 0.2),
		"flag": {"type": "morocco", "c1": Color(0.76,0.09,0.09), "c2": Color(0,0.39,0.2)}},
	{"name": "Croatia",      "abbr": "CRO", "color": Color(0.9,   0.06,  0.06),   "accent": Color(0.06, 0.38,  0.75),
		"flag": {"type": "h_stripes", "colors": [Color(0.76,0.08,0.08), Color(1,1,1), Color(0.06,0.38,0.75)]}},
	# Group G
	{"name": "Brazil",       "abbr": "BRA", "color": Color(0,     0.612, 0.231),  "accent": Color(1,    0.875, 0),
		"flag": {"type": "diamond", "c1": Color(0,0.612,0.231), "c2": Color(1,0.875,0), "c3": Color(0,0.24,0.56)}},
	{"name": "Serbia",       "abbr": "SRB", "color": Color(0.15,  0.22,  0.58),   "accent": Color(0.82, 0.1,   0.1),
		"flag": {"type": "h_stripes", "colors": [Color(0.76,0.08,0.08), Color(0.15,0.22,0.58), Color(1,1,1)]}},
	{"name": "Switzerland",  "abbr": "SUI", "color": Color(0.82,  0.07,  0.07),   "accent": Color(1,    1,     1),
		"flag": {"type": "swiss_cross", "c1": Color(0.82,0.07,0.07), "c2": Color(1,1,1)}},
	{"name": "Cameroon",     "abbr": "CMR", "color": Color(0.02,  0.47,  0.18),   "accent": Color(1,    0.78,  0),
		"flag": {"type": "v_stripes", "colors": [Color(0.02,0.47,0.18), Color(0.76,0.08,0.08), Color(0.95,0.75,0)]}},
	# Group H
	{"name": "Portugal",     "abbr": "POR", "color": Color(0,     0.4,   0),      "accent": Color(1,    0,     0),
		"flag": {"type": "v_stripes", "colors": [Color(0,0.4,0), Color(0.76,0.08,0.08)]}},
	{"name": "Ghana",        "abbr": "GHA", "color": Color(0.05,  0.05,  0.05),   "accent": Color(0.95, 0.75,  0),
		"flag": {"type": "h_stripes", "colors": [Color(0.76,0.08,0.08), Color(0.95,0.75,0), Color(0.02,0.47,0.18)]}},
	{"name": "Uruguay",      "abbr": "URU", "color": Color(0,     0.74,  0.83),   "accent": Color(1,    1,     1),
		"flag": {"type": "h_stripes", "colors": [Color(1,1,1), Color(0,0.74,0.83), Color(1,1,1), Color(0,0.74,0.83)]}},
	{"name": "South Korea",  "abbr": "KOR", "color": Color(0.82,  0.1,   0.1),    "accent": Color(0,    0.25,  0.62),
		"flag": {"type": "korea", "c2": Color(0.82,0.1,0.1), "c3": Color(0,0.25,0.62)}},
]

# 8 groups of 4 team indices (matching 2022 World Cup)
const GROUPS: Array = [
	{"name": "A", "teams": [0,  1,  2,  3]},
	{"name": "B", "teams": [4,  5,  6,  7]},
	{"name": "C", "teams": [8,  9,  10, 11]},
	{"name": "D", "teams": [12, 13, 14, 15]},
	{"name": "E", "teams": [16, 17, 18, 19]},
	{"name": "F", "teams": [20, 21, 22, 23]},
	{"name": "G", "teams": [24, 25, 26, 27]},
	{"name": "H", "teams": [28, 29, 30, 31]},
]

# Local-index pairs within each group (0-3), standard WC round-robin
const GROUP_SCHEDULE: Array = [
	[0, 1], [2, 3],
	[0, 2], [1, 3],
	[0, 3], [1, 2],
]
