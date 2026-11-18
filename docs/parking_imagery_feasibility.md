# Parking imagery feasibility

## Target location

The address `4000 S Quad Dr, Baton Rouge, LA 70808` is identified in LSU
planning material as the Touchdown Village parking lot.

## What can be added to GeauxPark

### Satellite or aerial basemap

A satellite layer is feasible as an optional visual basemap. Mapbox Satellite
provides raster XYZ tiles and an official Flutter SDK that supports Android,
iOS, and web. Google Map Tiles also provides satellite and photorealistic 3D
tiles, but requires a billed Google Cloud project, API-key protection, and
session-token handling.

Satellite imagery must be labeled as reference imagery, not live occupancy.
Google explicitly states that its satellite and aerial imagery is not real
time. Mapbox describes its satellite product as a composite optimized for a
balance of recency and appearance rather than a live feed.

### LiDAR

LiDAR is useful for offline site geometry: lot boundaries, terrain, drainage,
building height, tree cover, accessible-route planning, and future 3D map
visualization. USGS 3DEP and LSU's Louisiana Atlas provide point clouds and
elevation products for this kind of analysis.

Public LiDAR is not a live sensor feed and cannot show whether a parking space
is occupied now.

## What is required for live parking

Reliable space or lot occupancy needs a ground-level data source:

1. LSU-provided entry and exit counters for the lot.
2. In-space magnetometer or ultrasonic sensors.
3. A permitted fixed camera with on-device vehicle counting that publishes
   only aggregate counts, not identifiable video.
4. Community availability reports as the interim fallback already supported by
   GeauxPark.

## Recommended path

1. Keep the current lightweight OpenStreetMap layer for the MVP.
2. Add an optional satellite toggle after choosing Mapbox or Google and setting
   up restricted credentials, billing limits, attribution, and usage terms.
3. Use LiDAR only as a one-time planning source for lot polygons or a future 3D
   campus view.
4. Ask LSU Parking or Facilities for an aggregate occupancy feed for Touchdown
   Village. This is the only option above that could provide dependable live
   availability without deploying new hardware.

## Primary references

- Google Map Tiles API: https://developers.google.com/maps/documentation/tile/overview
- Google Earth imagery collection: https://support.google.com/earth/answer/6327779
- Mapbox Satellite: https://docs.mapbox.com/data/tilesets/reference/mapbox-satellite/
- Mapbox Flutter SDK: https://docs.mapbox.com/flutter/maps/api/latest/
- USGS Lidar Explorer: https://www.usgs.gov/tools/lidarexplorer
- LSU Atlas LiDAR Downloader: https://maps.ga.lsu.edu/lidar2000/
