# TODO - OfflineMedic (Map + Error Fix)

## Step 1: Implement offline-capable map UI
- [ ] Replace placeholder `MapScreen` with `flutter_map` implementation (done after step 1)
- [ ] Add `TileLayer` + offline caching using `flutter_map_cache`
- [ ] Add `MarkerLayer` for nearby hospitals

## Step 2: Implement hospital data + nearest sorting (offline computation)
- [ ] Implement hospital repository/model loader reading from `data/Hospitals_data`
- [ ] Compute distance from device GPS (if permission granted)
- [ ] Sort and show nearest hospitals in list + map markers

## Step 3: Enable directions + call actions
- [ ] On hospital tap: show bottom sheet with distance and actions
- [ ] Directions: open external browser/Maps URL to hospital coordinates
- [ ] Call: use `url_launcher` with `tel:` (hospital number / default emergency number)

## Step 4: Fix lint issues
- [ ] Remove unused `summary` in `DashboardScreen`
- [ ] Apply trivial `const` cleanups

## Step 5: Verification
- [ ] Run `flutter analyze`
- [ ] Run `flutter test`
- [ ] Manual run on Android: verify map loads + markers + tap actions

