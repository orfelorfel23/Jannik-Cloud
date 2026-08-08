#!/usr/bin/env python3
"""
Jannik-Cloud — Dashboard Auto-Discovery Generator
Scans services/ directory, checks for service.enabled and *.caddy files,
and generates configurations for both:
  1. Homepage (services.yaml)
  2. Custom Jannik-Cloud Hub (data.json & www assets)
"""

import os
import sys
import re
import json
from pathlib import Path

# --- Category Definitions & Service Mappings ---
CATEGORY_MAPPING = {
    # Cloud & Storage
    "nextcloud": ("Cloud & Speicher", "nextcloud.png", "fa-cloud"),
    "ocis": ("Cloud & Speicher", "owncloud.png", "fa-cloud"),
    "owncloud": ("Cloud & Speicher", "owncloud.png", "fa-cloud"),
    "syncthing": ("Cloud & Speicher", "syncthing.png", "fa-sync-alt"),
    "archivebox": ("Cloud & Speicher", "archivebox.png", "fa-archive"),

    # Security & Auth
    "vaultwarden": ("Sicherheit & Auth", "vaultwarden.png", "fa-shield-halved"),
    "authentik": ("Sicherheit & Auth", "authentik.png", "fa-key"),
    "netbird": ("Sicherheit & Auth", "netbird.png", "fa-network-wired"),

    # AI & Knowledge
    "librechat": ("KI & Wissen", "librechat.png", "fa-robot"),
    "litellm": ("KI & Wissen", "openai.png", "fa-brain"),
    "mediawiki": ("KI & Wissen", "wikipedia.png", "fa-book-open"),
    "outline": ("KI & Wissen", "outline.png", "fa-book"),
    "ilias": ("KI & Wissen", "ilias.png", "fa-graduation-cap"),
    "mc-survival-wiki": ("KI & Wissen", "minecraft.png", "fa-cube"),

    # DevOps & Server
    "gitea": ("DevOps & Server", "gitea.png", "fa-code-branch"),
    "portainer": ("DevOps & Server", "portainer.png", "fa-docker"),
    "n8n": ("DevOps & Server", "n8n.png", "fa-diagram-project"),
    "kestra": ("DevOps & Server", "kestra.png", "fa-gears"),
    "webhook": ("DevOps & Server", "webhook.png", "fa-bolt"),
    "rustdesk": ("DevOps & Server", "rustdesk.png", "fa-desktop"),
    "postgres": ("DevOps & Server", "postgresql.png", "fa-database"),
    "redis": ("DevOps & Server", "redis.png", "fa-server"),
    "backup": ("DevOps & Server", "duplicati.png", "fa-floppy-disk"),
    "fwproxy": ("DevOps & Server", "caddy.png", "fa-route"),

    # Media & Audio
    "navidrome": ("Medien & Audio", "navidrome.png", "fa-music"),
    "deezer": ("Medien & Audio", "deezer.png", "fa-headphones"),
    "spotify": ("Medien & Audio", "spotify.png", "fa-spotify"),
    "linus": ("Medien & Audio", "sound.png", "fa-volume-high"),
    "lsound": ("Medien & Audio", "sound.png", "fa-volume-high"),
    "handbrake": ("Medien & Audio", "handbrake.png", "fa-film"),
    "melodymuse": ("Medien & Audio", "music.png", "fa-compact-disc"),
    "soulsync": ("Medien & Audio", "music.png", "fa-radio"),

    # Smart Home & 3D
    "homeassistant": ("Smart Home & 3D", "home-assistant.png", "fa-house-signal"),
    "iobroker": ("Smart Home & 3D", "iobroker.png", "fa-microchip"),
    "spoolman": ("Smart Home & 3D", "spoolman.png", "fa-cubes"),

    # Tools & Productivity
    "searxng": ("Tools & Produktivität", "searxng.png", "fa-magnifying-glass"),
    "stirlingpdf": ("Tools & Produktivität", "stirling-pdf.png", "fa-file-pdf"),
    "linkding": ("Tools & Produktivität", "linkding.png", "fa-bookmark"),
    "baserow": ("Tools & Produktivität", "baserow.png", "fa-table"),
    "simple-url-shortener": ("Tools & Produktivität", "link.png", "fa-link"),
    "slash": ("Tools & Produktivität", "slash.png", "fa-hashtag"),
    "zipline": ("Tools & Produktivität", "zipline.png", "fa-cloud-arrow-up"),
    "clink": ("Tools & Produktivität", "link.png", "fa-paperclip"),
    "bit": ("Tools & Produktivität", "link.png", "fa-arrow-up-right-from-square"),
    "dub": ("Tools & Produktivität", "link.png", "fa-link"),
    "ntfy": ("Tools & Produktivität", "ntfy.png", "fa-bell"),

    # Emergency & CBRN
    "cbrn": ("Einsatz & CBRN", "fire.png", "fa-fire-extinguisher"),
    "erkw": ("Einsatz & CBRN", "fire.png", "fa-truck-medical"),

    # Community & Apps
    "quizalarm": ("Community & Apps", "quiz.png", "fa-gamepad"),
    "quizalarm-stat": ("Community & Apps", "quiz.png", "fa-chart-line"),
    "nein": ("Community & Apps", "smile.png", "fa-hand"),
    "godmod3": ("Community & Apps", "smile.png", "fa-wand-magic-sparkles"),
    "jga": ("Community & Apps", "users.png", "fa-users"),
    "schnappix": ("Community & Apps", "camera.png", "fa-camera"),
}

CATEGORY_ORDER = [
    "Cloud & Speicher",
    "Sicherheit & Auth",
    "KI & Wissen",
    "DevOps & Server",
    "Medien & Audio",
    "Smart Home & 3D",
    "Tools & Produktivität",
    "Einsatz & CBRN",
    "Community & Apps",
    "Weitere Dienste",
]

CATEGORY_ICONS = {
    "Cloud & Speicher": "fa-cloud",
    "Sicherheit & Auth": "fa-shield-halved",
    "KI & Wissen": "fa-brain",
    "DevOps & Server": "fa-server",
    "Medien & Audio": "fa-music",
    "Smart Home & 3D": "fa-house-signal",
    "Tools & Produktivität": "fa-wrench",
    "Einsatz & CBRN": "fa-fire-extinguisher",
    "Community & Apps": "fa-users",
    "Weitere Dienste": "fa-cubes",
}


def find_repo_root(start_dir=None):
    """Locate the root of Jannik-Cloud repo."""
    if start_dir:
        p = Path(start_dir).resolve()
        if (p / "services").is_dir():
            return p
    # Fallback checks
    candidates = [
        Path(__file__).resolve().parent.parent,
        Path("/opt/Jannik-Cloud"),
        Path.cwd(),
    ]
    for c in candidates:
        if (c / "services").is_dir():
            return c
    return Path.cwd()


def extract_domains_from_caddy(caddy_path):
    """Extract public subdomains from a .caddy file."""
    if not caddy_path.is_file():
        return []
    try:
        content = caddy_path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return []

    domains = []
    # Match domain lines like: sub.orfel.de, other.orfel.de { ...
    for line in content.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.startswith("{"):
            continue
        # Extract hostnames ending with .orfel.de or domain-like tokens before {
        header = line.split("{")[0]
        tokens = [t.strip().rstrip(",") for t in header.split() if t.strip()]
        for token in tokens:
            if re.match(r"^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$", token):
                domains.append(token)
    return domains


def extract_readme_metadata(readme_path, service_name):
    """Extract display title and description from service README.md."""
    default_title = service_name.replace("-", " ").title()
    default_desc = "Jannik-Cloud Service"

    if not readme_path.is_file():
        return default_title, default_desc

    try:
        lines = readme_path.read_text(encoding="utf-8", errors="ignore").splitlines()
    except Exception:
        return default_title, default_desc

    for line in lines:
        line = line.strip()
        if line.startswith("# "):
            title_part = line[2:].strip()
            # Check for pattern "Title — Description" or "Title - Description"
            m = re.split(r"\s*[-—–]\s*", title_part, maxsplit=1)
            if len(m) == 2:
                return m[0].strip(), m[1].strip()
            else:
                return m[0].strip(), default_desc

    return default_title, default_desc


def scan_services(repo_root):
    """Scan all service directories and collect metadata."""
    services_dir = repo_root / "services"
    discovered = []

    if not services_dir.is_dir():
        print(f"[WARN] Services directory not found at {services_dir}")
        return discovered

    for svc_dir in sorted(services_dir.iterdir()):
        if not svc_dir.is_dir():
            continue
        svc_name = svc_dir.name

        # Skip dashboard, homepage or infra internal helpers from discovery if needed
        # (homepage and dashboard can be listed or self-referenced)
        is_enabled = (svc_dir / "service.enabled").is_file()
        compose_file = svc_dir / "docker-compose.yml"
        has_compose = compose_file.is_file()

        # Find .caddy file
        caddy_files = list(svc_dir.glob("*.caddy"))
        domains = []
        if caddy_files:
            domains = extract_domains_from_caddy(caddy_files[0])

        # Find display title and description
        readme_file = svc_dir / "README.md"
        title, desc = extract_readme_metadata(readme_file, svc_name)

        # Determine category & icon
        if svc_name in CATEGORY_MAPPING:
            cat_name, hp_icon, fa_icon = CATEGORY_MAPPING[svc_name]
        else:
            # Fallback for unknown / newly added services
            cat_name = "Weitere Dienste"
            hp_icon = "docker.png"
            fa_icon = "fa-cubes"

        # Determine primary URL
        primary_url = None
        if domains:
            primary_url = f"https://{domains[0]}"
        elif (svc_dir / "service.domain").is_file():
            primary_url = f"https://{(svc_dir / 'service.domain').read_text().strip()}"

        discovered.append({
            "id": svc_name,
            "title": title,
            "description": desc,
            "category": cat_name,
            "homepage_icon": hp_icon,
            "fa_icon": fa_icon,
            "domains": domains,
            "url": primary_url,
            "enabled": is_enabled,
            "has_compose": has_compose,
        })

    return discovered


def generate_homepage_yaml(services, output_file):
    """Generate Homepage services.yaml configuration."""
    output_file.parent.mkdir(parents=True, exist_ok=True)

    # Group active services with URLs by category
    categories = {}
    for s in services:
        if not s["enabled"] or not s["url"]:
            continue
        # Skip homepage itself from its own dashboard
        if s["id"] in ("homepage", "caddy", "postgres", "redis", "backup"):
            continue
        cat = s["category"]
        if cat not in categories:
            categories[cat] = []
        categories[cat].append(s)

    lines = [
        "---",
        "# Homepage Services Configuration — Auto-Generated by Jannik-Cloud deploy_script",
        "# DO NOT EDIT DIRECTLY — Regenerated on each deployment.",
        "",
    ]

    for cat in CATEGORY_ORDER:
        if cat not in categories or not categories[cat]:
            continue
        lines.append(f"- {cat}:")
        for s in categories[cat]:
            lines.append(f"    - {s['title']}:")
            lines.append(f"        icon: {s['homepage_icon']}")
            lines.append(f"        href: {s['url']}")
            lines.append(f"        description: {s['description']}")
            lines.append(f"        ping: {s['url']}")
        lines.append("")

    content = "\n".join(lines)
    output_file.write_text(content, encoding="utf-8")
    print(f"[GEN] Generated Homepage services.yaml -> {output_file}")


def generate_custom_dashboard_data(services, output_file):
    """Generate JSON data for the custom dashboard."""
    output_file.parent.mkdir(parents=True, exist_ok=True)

    grouped = {}
    for cat in CATEGORY_ORDER:
        grouped[cat] = {
            "name": cat,
            "icon": CATEGORY_ICONS.get(cat, "fa-cubes"),
            "services": [],
        }

    active_count = 0
    for s in services:
        if not s["enabled"] or not s["url"]:
            continue
        if s["id"] in ("caddy", "postgres", "redis", "backup"):
            continue
        active_count += 1
        cat = s["category"]
        if cat not in grouped:
            grouped[cat] = {
                "name": cat,
                "icon": "fa-cubes",
                "services": [],
            }
        grouped[cat]["services"].append({
            "id": s["id"],
            "title": s["title"],
            "description": s["description"],
            "url": s["url"],
            "domains": s["domains"],
            "icon": s["fa_icon"],
            "category": cat,
        })

    # Filter out empty categories
    category_list = [grouped[c] for c in CATEGORY_ORDER if c in grouped and grouped[c]["services"]]

    data = {
        "title": "Jannik-Cloud Hub",
        "description": "Zentrale Übersicht aller aktiven Cloud-Dienste",
        "activeCount": active_count,
        "categories": category_list,
    }

    output_file.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[GEN] Generated Dashboard data.json -> {output_file}")


def main():
    repo_arg = sys.argv[1] if len(sys.argv) > 1 else None
    repo_root = find_repo_root(repo_arg)
    print(f"[GEN] Jannik-Cloud Dashboard Generator running on: {repo_root}")

    services = scan_services(repo_root)
    active_svcs = [s for s in services if s["enabled"]]
    print(f"[GEN] Discovered {len(services)} total services ({len(active_svcs)} active).")

    # 1. Homepage config path (both local repo template & persistent server volume)
    hp_local = repo_root / "services" / "homepage" / "config" / "services.yaml"
    generate_homepage_yaml(services, hp_local)

    server_hp_vol = Path("/mnt/Jannik-Cloud-Volume-01/homepage/config/services.yaml")
    if server_hp_vol.parent.is_dir():
        generate_homepage_yaml(services, server_hp_vol)

    # 2. Custom Dashboard data path (both local repo www & persistent server volume)
    dash_local = repo_root / "services" / "dashboard" / "www" / "data.json"
    generate_custom_dashboard_data(services, dash_local)

    server_dash_vol = Path("/mnt/Jannik-Cloud-Volume-01/dashboard/data.json")
    if server_dash_vol.parent.is_dir():
        generate_custom_dashboard_data(services, server_dash_vol)

    print("[GEN] Dashboard generation complete!")


if __name__ == "__main__":
    main()
