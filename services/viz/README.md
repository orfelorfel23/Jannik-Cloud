# Viz — Audio Visualizer Studio for DaVinci Resolve

**Viz** is an audio-reactive visualizer studio designed for creating professional music videos and social media clips (16:9 YouTube, 9:16 Shorts/TikTok, 1:1 Instagram) with transparent video export (**ProRes 4444 with Alpha**, **WebM Alpha**, **MP4**).

- **Domain**: [viz.orfel.de](https://viz.orfel.de)
- **Port**: `849`
- **Source Repository**: [https://git.orfel.de/Jannik/Viz.git](https://git.orfel.de/Jannik/Viz.git)
- **Persistent Volume**: `/mnt/Jannik-Cloud-Volume-01/viz:/data`
- **Cleanup Policy**: All temporary uploads/renders in `/data/temp` and `/data/uploads` are automatically cleaned on startup/rebuild.
