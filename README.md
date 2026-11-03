# PROJECT Y – Ticketsystem

## Enthalten
- `index.html`: eine Web-App mit zwei getrennten Ansichten:
  - `?mode=admin` – Veranstalter-Generator
  - `?mode=scan` – Türsteher-Scanner
- `supabase.sql`: Tabellen, Rollen, Zugriffsschutz und Prüf-Funktionen.
- Mehrere Türsteher können zeitgleich mit eigenen Accounts dieselbe Online-Datenbank nutzen.
- Scans entwerten Tickets ausdrücklich NICHT. Nur `status = revoked` macht ein Ticket ungültig.

## 1. Kostenlose Online-Datenbank einrichten
1. Bei https://supabase.com ein kostenloses Projekt erstellen.
2. In **SQL Editor** den kompletten Inhalt von `supabase.sql` ausführen.
3. In **Project Settings → API** die Project URL und den `anon` / publishable key kopieren.
4. In `index.html` oben im Script diese zwei Platzhalter ersetzen:
   - `DEINE_SUPABASE_PROJECT_URL`
   - `DEIN_SUPABASE_ANON_PUBLIC_KEY`
   Niemals den `service_role` key in die HTML-Datei eintragen.

## 2. Zugänge erstellen
1. In Supabase unter **Authentication → Users** einen Benutzer für dich anlegen (E-Mail + Passwort).
2. Benutzer für jeden Türsteher einzeln anlegen.
3. Die UUIDs der Benutzer kopieren.
4. In SQL Editor ausführen (UUIDs ersetzen):
```sql
insert into public.project_y_profiles(user_id, role) values
('UUID-DES-VERANSTALTERS','admin'),
('UUID-TUERSTEHER-1','bouncer'),
('UUID-TUERSTEHER-2','bouncer');
```
Nur `admin` kann Tickets ausstellen, einsehen, sperren oder freigeben. `bouncer` kann nur QR-Codes prüfen.

## 3. Web-App veröffentlichen
Die Dateien können auf einem statischen HTTPS-Host veröffentlicht werden, z. B. GitHub Pages oder Netlify.
- `index.html` hochladen/deployen.
- Beide Ansichten verwenden dieselbe URL:
  - `https://DEINE-DOMAIN/?mode=admin`
  - `https://DEINE-DOMAIN/?mode=scan`
- Jeder Türsteher öffnet die Scanner-Adresse auf seinem Smartphone und meldet sich mit seinem eigenen Konto an.
- Für die Kamera ist HTTPS erforderlich (bei GitHub Pages/Netlify vorhanden). Jeder Türsteher muss den Kamerazugriff erlauben.

## 4. Bedienung
1. Im Generator Namen eintragen – ein Name pro Zeile.
2. „Tickets erstellen“ anklicken. Für jedes Ticket wird ein eigener QR-Code erzeugt und ein individuelles PDF heruntergeladen.
3. Am Einlass den QR-Code scannen.
4. Auf dem Scanner erscheinen Name, Ticketnummer und Status. Ausweis mit Ticketnamen vergleichen.
5. Wenn ein Ticket gesperrt werden soll, im Generator „SPERREN“ drücken.

## Wichtige Hinweise / aktueller Funktionsumfang
- Der QR-Code enthält einen zufälligen, nicht erratbaren Token. In der Datenbank liegt nur dessen SHA-256-Hash.
- Der QR-Token wird nach der Erstellung nicht erneut aus der Datenbank ausgelesen. Deshalb ist ein PDF-Neudruck aus der Ticketliste aktuell absichtlich nicht möglich. Die beim Erstellen erzeugten PDFs sofort sicher speichern. Ein späterer sicherer Reprint-Workflow braucht verschlüsselte Token-Aufbewahrung oder eine erneute Ausstellung.
- Die PDF-Dateien werden einzeln vom Browser heruntergeladen. Je nach Browser müssen mehrere Downloads erlaubt werden.
- Die kostenlose Datenbank und der Hosting-Anbieter haben Nutzungs-/Inaktivitätsgrenzen. Für den Eventtag Internet am Einlass einplanen und vorher mit mehreren Handys testen.
- Das ist ein einsatzfähiger Startstand, aber vor echtem Einlass bitte einen vollständigen Belastungs- und Sicherheitstest durchführen. Kein Offline-Modus.
