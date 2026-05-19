# Sølvrævene iOS

Privat iOS-app til at holde styr på gruppens ture.

## Tilføj en ny tur (uden build)

Rediger filen [`Solvraevene/Resources/trips.json`](Solvraevene/Resources/trips.json) direkte i GitHub:

1. Åbn filen på GitHub og klik blyantsikonet **✏️ Edit this file**.
2. Tilføj en ny linje øverst i JSON-arrayet:

```json
{ "date": "YYYY-MM-DD", "organizers": ["XXX","YYY"] }
```

Valgfrie felter:

| Felt | Beskrivelse |
|------|-------------|
| `location` | Bynavn, f.eks. `"Aarhus"` – bruges til automatisk geokodning (koordinater + landekode via Apple) |
| `photoAlbumURL` | Link til Google Photos-album, f.eks. `"https://photos.app.goo.gl/..."` |

**Arrangør-initialer:** `DM` · `NWH` · `MC` · `MSA` · `PHA` · `MR`

3. Vælg **Commit directly to `main`** og klik **Commit changes**.

Appen henter `trips.json` live ved opstart (med automatisk fallback til den indbyggede kopi, hvis der ikke er netværk), så opdateringen er synlig i appen uden nyt build.

---

## Byg og udgiv til TestFlight

Kør workflow **TestFlight** manuelt via GitHub Actions:  
**Actions → TestFlight → Run workflow → Run workflow**
