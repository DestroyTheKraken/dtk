# DTK unified project structure

Created by integrating:

1. **Archived branding** — `/mnt/systems_admin/joshua/HICKMAN_ROOT/Joshua/Projects/DTK`  
   (Content_Master, About, website HTML, logo, headshot, mountain imagery)
2. **Valley Tech Support** — `~/Documents/valley-tech-support` (symlink `vts/`)
3. **Sovereign Media Hub** — `~/HickMedia` (symlink `products/media-hub`)

```
~/DTK/
├── README.md / AGENTS.md
├── brand/                 # Marketing + about SoT
├── site/                  # Public website + publish.sh
│   ├── index.html         # Full branded landing (from archive + installers)
│   ├── img/
│   └── publish.sh
├── products/
│   └── media-hub → HickMedia
├── vts → valley-tech-support
└── archive/NAS-POINTER.md
```

Git: `vts` and `media-hub` keep their own repos. `~/DTK` can be its own git later for brand/site only.
