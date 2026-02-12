# HomeAssistant - Home Automation

## Overview
Home Assistant is an open-source home automation platform that allows you to control and automate your smart home devices.

## Configuration
- **Domain**: https://home.orfel.de
- **Internal Port**: 11012
- **Timezone**: UTC
- **User**: Jannik

## Features
- Control smart home devices (lights, thermostats, locks, etc.)
- Automation and scripting
- Dashboard and mobile app
- 1000+ integrations with IoT devices
- Voice control with add-ons
- Security monitoring
- Energy monitoring

## Supported Devices/Services
- Philips Hue, LIFX (smart lights)
- Nest, Ecobee, Tado (thermostats)
- August, Yale, Nuki (smart locks)
- OpenWeather, Weatherflow (weather)
- MQTT, Z-Wave, Zigbee (protocols)
- And many more...

## First Run
1. Navigate to https://home.orfel.de
2. Create your user account
3. Start adding devices/integrations

## Data Storage
- Configuration and data: /mnt/Jannik-Cloud-Volume-01/homeassistant

## YAML Configuration
Edit `/mnt/Jannik-Cloud-Volume-01/homeassistant/configuration.yaml` for advanced configuration.

## Logs
```bash
docker logs homeassistant
```

## Mobile App
Download the Home Assistant app for iOS/Android for remote control and automation.

## Blueprints
Community-shared automation blueprints available on GitHub.
