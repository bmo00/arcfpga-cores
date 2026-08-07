# arcfpga-cores

FPGA arcade cores built on Jose Tejada's (jotego) [**JTFRAME**](https://github.com/jotego/jtframe)
framework, with an added **neptUNO+** target alongside the targets JTFRAME already supports
(MiSTer, MiST, SiDi, SiDi128, Pocket, NeptUNO).

> Not affiliated with or endorsed by jotego.

## Contents

- [`cores/`](cores/) — one arcade core per subdirectory: HDL, config, and its own README/doc. See
  [Cores](#cores) below for the current list.
- [`modules/`](modules/) — shared HDL modules (CPUs, sound chips, etc.) used by the cores above,
  including [`modules/jtframe`](modules/jtframe) itself.
- [`releases/`](releases/) — built binaries per core: a dated `.rbf` per target, `.mra` files
  (MiSTer) and `.arc` files (MiST-family targets).

## Cores

Cores are listed per FPGA target. Core names follow the release `.rbf` filename (without the
`_YYYYMMDD` date suffix). Only cores with a published release are shown, along with the parents
(game ROMsets) each core supports and the date of its latest release build.

### MiSTer

| Core | Parents | Description | Last update |
|---|---|---|---|
| [`jtriders`](cores/riders/README.md) | Golfing Greats (World, version L) (`glfgreat`)<br>Lightning Fighters (World) (`lgtnfght`)<br>Sunset Riders (4 Players ver EAC) (`ssriders`)<br>Teenage Mutant Ninja Turtles: Turtles in Time (4 Players ver UAA) (`tmnt2`) | Konami, 1990–1991 — JOTEGO port | 2026-08-07 |
| [`mystston`](cores/mystston/README.md) | Mysterious Stones: Dr. John's Adventure (`mystston`) | Technos Japan, 1984 | 2026-08-07 |

### NeptUNO+

| Core | Parents | Description | Last update |
|---|---|---|---|
| [`aligator`](cores/aligator/) | Alligator Hunt (World, protected, checksum 2B34128B) (`aligator`) | Gaelco, 1994 — jlrh port | 2026-08-07 |
| [`asterix`](cores/asterix/) | Asterix (FF ver EAD) (`asterix`) | Konami, 1992 — jlrh port | 2026-08-07 |
| [`bigkarnk`](cores/bigkarnk/) | Big Karnak (ver. 1.0, checksum 1e38c94) (`bigkarnk`) | Gaelco, 1991 — jlrh port | 2026-08-07 |
| [`biomtoy`](cores/biomtoy/) | Biomechanical Toy (ver. 1.0.1885, checksum 69f5e032) (`biomtoy`) | Gaelco / Zeus, 1995 — jlrh port | 2026-08-07 |
| [`empirecity`](cores/empirecity/) | Empire City: 1931 (bootleg?) (`empcity`) | Seibu Kaihatsu, 1986 — jlrh port | 2026-08-07 |
| [`glass`](cores/glass/) | Glass (ver 1.1, Break Edition, checksum 49D5E66B, Version 1994, set 2) (`glassa`) | OMK / Gaelco, 1994 — jlrh port | 2026-08-07 |
| [`jt1942`](cores/1942/README.md) | 1942 (Revision B) (`1942`)<br>Pirate Ship Higemaru (`higemaru`)<br>Vulgus (set 1) (`vulgus`) | Capcom, 1984 — JOTEGO port | 2026-08-07 |
| [`jt1943`](cores/1943/README.md) | 1943 Kai: Midway Kaisen (Japan) (`1943kai`)<br>1943: The Battle of Midway (Euro) (`1943`)<br>1943: The Battle of Midway Mark II (US) (`1943mii`) | Capcom, 1987 — JOTEGO port | 2026-08-07 |
| [`jtajax`](cores/ajax/) | Ajax (`ajax`) | Konami, 1987 — JOTEGO port | 2026-08-07 |
| [`jtaliens`](cores/aliens/README.md) | Aliens (World set 1) (`aliens`)<br>Crime Fighters (World 2 players) (`crimfght`)<br>Gang Busters (set 1) (`gbusters`)<br>Super Contra (set 1) (`scontra`)<br>Thunder Cross (set 1) (`thunderx`) | Konami, 1988–1990 — JOTEGO port | 2026-08-07 |
| [`jtbiocom`](cores/biocom/README.md) | Bionic Commando (Euro) (`bionicc`) | Capcom, 1987 — JOTEGO port | 2026-08-07 |
| [`jtbtiger`](cores/btiger/README.md) | Black Tiger (`blktiger`) | Capcom, 1987 — JOTEGO port | 2026-08-07 |
| [`jtbubl`](cores/bubl/README.md) | Bubble Bobble (Japan, Ver 0.1) (`bublbobl`)<br>Tokio - Scramble Formation (newer) (`tokio`) | Taito Corporation, 1986 — JOTEGO port | 2026-08-07 |
| [`jtcastle`](cores/castle/README.md) | Haunted Castle (version M) (`hcastle`) | Konami, 1988 — JOTEGO port | 2026-08-07 |
| [`jtcircus`](cores/circus/) | Circus Charlie (level select, set 1) (`circusc`) | Konami, 1984 — JOTEGO port | 2026-08-07 |
| [`jtcommnd`](cores/commnd/README.md) | Commando (World) (`commando`) | Capcom, 1985 — JOTEGO port | 2026-08-07 |
| [`jtcomsc`](cores/comsc/README.md) | Combat School (joystick) (`combatsc`) | Konami, 1988 — JOTEGO port | 2026-08-07 |
| [`jtcontra`](cores/contra/README.md) | Contra (US - Asia, set 1) (`contra`) | Konami, 1987 — JOTEGO port | 2026-08-07 |
| [`jtcop`](cores/cop/) | Hippodrome (US) (`hippodrm`)<br>Robocop (World, revision 4) (`robocop`) | Data East Corporation, 1988–1989 — JOTEGO port | 2026-08-07 |
| [`jtcps1`](cores/cps1/README.md) | 1941: Counter Attack (World 900227) (`1941`)<br>Adventure Quiz Capcom World 2 (Japan 920611) (`cworld2j`)<br>Captain Commando (World 911202) (`captcomm`)<br>Carrier Air Wing (World 901012) (`cawing`)<br>Dynasty Wars (USA, B-Board 89624B-?) (`dynwar`)<br>Final Fight (World, set 1) (`ffight`)<br>Forgotten Worlds (World, newer) (`forgottn`)<br>Ghouls'n Ghosts (World) (`ghouls`)<br>Gulun.Pa! (Japan 931220 L) (prototype) (`gulunpa`)<br>Knights of the Round (World 911127) (`knights`)<br>Magic Sword: Heroic Fantasy (World 900725) (`msword`)<br>Magical Pumpkin: Puroland de Daibouken (Japan 960712) (`mpumpkin`)<br>Mega Man: The Power Battle (CPS1, USA 951006) (`megaman`)<br>Mega Twins (World 900619) (`mtwins`)<br>Mercs (World 900302) (`mercs`)<br>Nemo (World 901130) (`nemo`)<br>Pang! 3 (Europe 950601) (`pang3`)<br>Pnickies (Japan 940608) (`pnickj`)<br>Pokonyan! Balloon (Japan 940322) (`pokonyan`)<br>Quiz & Dragons: Capcom Quiz Game (USA 920701) (`qad`)<br>Quiz Tonosama no Yabou 2: Zenkoku-ban (Japan 950123) (`qtono2j`)<br>Street Fighter II': Champion Edition (World 920513) (`sf2ce`)<br>Street Fighter II': Champion Re-Edit (Hack, v0.29.7) (`sf2cre`)<br>Street Fighter II': Hyper Fighting (World 921209) (`sf2hf`)<br>Street Fighter II': Special Champion Edition (Sr Street hack) (`sf2hfsce`)<br>Street Fighter II: The World Warrior (World 910522) (`sf2`)<br>Street Fighter Zero (CPS Changer, Japan 951020) (`sfzch`)<br>Strider (USA, B-Board 89624B-2) (`strider`)<br>The King of Dragons (World 910805) (`kod`)<br>Three Wonders (World 910520) (`3wonders`)<br>U.N. Squadron (USA) (`unsquad`)<br>Varth: Operation Thunderstorm (World 920714) (`varth`)<br>Willow (World) (`willow`) | Capcom, 1988–1996 — JOTEGO port | 2026-08-07 |
| [`jtcps15`](cores/cps15/README.md) | Cadillacs and Dinosaurs (World 930201) (`dino`)<br>Muscle Bomber Duo: Ultimate Team Battle (World 931206) (`mbombrd`)<br>Saturday Night Slam Masters (World 930713) (`slammast`)<br>Tenchi wo Kurau II: Sekiheki no Tatakai (CPS Changer, Japan 921031) (`wofch`)<br>The Punisher (World 930422) (`punisher`)<br>Warriors of Fate (World 921031) (`wof`) | Capcom, 1992–1994 — JOTEGO port | 2026-08-07 |
| [`jtcps2`](cores/cps2/README.md) | 1944: The Loop Master (Europe 000620) (`1944`)<br>19XX: The War Against Destiny (Europe 960104) (`19xx`)<br>Alien vs. Predator (Europe 940520) (`avsp`)<br>Armored Warriors (Europe 941024) (`armwar`)<br>Battle Circuit (Europe 970319) (`batcir`)<br>Capcom Sports Club (Europe 971017) (`csclub`)<br>Cyberbots: Fullmetal Madness (Europe 950424) (`cybots`)<br>Darkstalkers: The Night Warriors (Europe 940705) (`dstlk`)<br>Dimahoo (Europe 000121) (`dimahoo`)<br>Dungeons & Dragons: Shadow over Mystara (Europe 960619) (`ddsom`)<br>Dungeons & Dragons: Tower of Doom (Europe 940412) (`ddtod`)<br>Eco Fighters (World 931203) (`ecofghtr`)<br>Giga Wing (USA 990222) (`gigawing`)<br>Hyper Street Fighter II: The Anniversary Edition (USA 040202) (`hsf2`)<br>Janpai Puzzle Choukou (Japan 010820) (`choko`)<br>Jyangokushi: Haoh no Saihai (Japan 990527) (`jyangoku`)<br>Mars Matrix: Hyper Solid Shooting (USA 000412) (`mmatrix`)<br>Marvel Super Heroes (Europe 951024) (`msh`)<br>Marvel Super Heroes Vs. Street Fighter (Europe 970625) (`mshvsf`)<br>Marvel Vs. Capcom: Clash of Super Heroes (Europe 980123) (`mvsc`)<br>Mega Man 2: The Power Fighters (USA 960708) (`megaman2`)<br>Mighty! Pang (Europe 001010) (`mpang`)<br>Night Warriors: Darkstalkers' Revenge (Europe 950316) (`nwarr`)<br>Progear (USA 010117) (`progear`)<br>Puzz Loop 2 (Europe 010302) (`pzloop2`)<br>Quiz Nanairo Dreams: Nijiirochou no Kiseki (Japan 960826) (`qndream`)<br>Ring of Destruction: Slammasters II (Europe 940902) (`ringdest`)<br>Street Fighter Alpha 2 (Europe 960229) (`sfa2`)<br>Street Fighter Alpha 3 (Europe 980904) (`sfa3`)<br>Street Fighter Alpha: Warriors' Dreams (Europe 950727) (`sfa`)<br>Street Fighter Zero 2 Alpha (Asia 960826) (`sfz2al`)<br>Super Gem Fighter: Mini Mix (USA 970904) (`sgemf`)<br>Super Puzzle Fighter II Turbo (Europe 960529) (`spf2t`)<br>Super Street Fighter II Turbo (World 940223) (`ssf2t`)<br>Super Street Fighter II: The New Challengers (World 931005) (`ssf2`)<br>Vampire Hunter 2: Darkstalkers Revenge (Japan 970929) (`vhunt2`)<br>Vampire Savior 2: The Lord of Vampire (Japan 970913) (`vsav2`)<br>Vampire Savior: The Lord of Vampire (Europe 970519) (`vsav`)<br>X-Men Vs. Street Fighter (Europe 961004) (`xmvsf`)<br>X-Men: Children of the Atom (Europe 950331) (`xmcota`) | Capcom, 1993–2004 — JOTEGO port | 2026-08-07 |
| [`jtdd`](cores/dd/README.md) | Double Dragon (World set 1) (`ddragon`) | Technos Japan (Taito license), 1987 — JOTEGO port | 2026-08-07 |
| [`jtdd2`](cores/dd2/README.md) | Double Dragon II: The Revenge (World) (`ddragon2`) | Technos Japan, 1988 — JOTEGO port | 2026-08-07 |
| [`jtddrbl`](cores/ddrbl/) | Double Dribble (`ddribble`) | Konami, 1986 — JOTEGO port | 2026-08-07 |
| [`jtexed`](cores/exed/README.md) | Exed Exes (`exedexes`) | Capcom, 1985 — JOTEGO port | 2026-08-07 |
| [`jtflane`](cores/flane/README.md) | Fast Lane (`fastlane`) | Konami, 1987 — JOTEGO port | 2026-08-07 |
| [`jtflstory`](cores/flstory/README.md) | Bronx (bootleg of Cycle Shooting) (`bronx`)<br>Cycle Shooting (`cyclshtg`)<br>N.Y. Captor (rev 2) (`nycaptor`)<br>Onna Sanshirou - Typhoon Gal (rev 1) (`onna34ro`)<br>Rumba Lumber (rev 1) (`rumba`)<br>The FairyLand Story (`flstory`)<br>Victorious Nine (`victnine`) | Taito, 1984–1986 — JOTEGO port | 2026-08-07 |
| [`jtfround`](cores/fround/README.md) | The Final Round (version M) (`fround`) | Konami, 1988 — JOTEGO port | 2026-08-07 |
| [`jtgaiden`](cores/gaiden/README.md) | Raiga - Strato Fighter (US) (`stratof`)<br>Shadow Warriors (World, set 1) (`shadoww`)<br>Wild Fang - Tecmo Knight (World?) (`wildfang`) | Tecmo, 1988–1991 — JOTEGO port | 2026-08-07 |
| [`jtgng`](cores/gng/README.md) | Ghosts'n Goblins (World? set 1) (`gng`) | Capcom, 1985 — JOTEGO port | 2026-08-07 |
| [`jtgunsmk`](cores/gunsmk/README.md) | Gun.Smoke (World, 1985-11-15) (`gunsmoke`) | Capcom, 1985 — JOTEGO port | 2026-08-07 |
| [`jtkarnov`](cores/karnov/) | Atomic Runner Chelnov (World) (`chelnov`)<br>Karnov (US, rev 6) (`karnov`)<br>Wonder Planet (Japan) (`wndrplnt`) | Data East Corporation, 1987–1988 — JOTEGO port | 2026-08-07 |
| [`jtkchamp`](cores/kchamp/README.md) | Karate Champ (US) (`kchamp`)<br>Karate Champ: Player Vs Player (US, set 1) (`kchampvs`) | Data East USA, 1984 — JOTEGO port | 2026-08-07 |
| [`jtkicker`](cores/kicker/README.md) | Kicker (`kicker`) | Konami, 1985 — JOTEGO port | 2026-08-07 |
| [`jtkiwi`](cores/kiwi/README.md) | Arkanoid - Revenge of DOH (World) (`arknoid2`)<br>Dr. Toppel's Adventure (World) (`drtoppel`)<br>Extermination (World) (`extrmatn`)<br>Insector X (World) (`insectx`)<br>Kabuki-Z (World) (`kabukiz`)<br>Kageki (World) (`kageki`)<br>The NewZealand Story (World, new version) (P0-043A PCB) (`tnzs`) | Taito Corporation Japan, 1987–1989 — JOTEGO port | 2026-08-07 |
| [`jtkunio`](cores/kunio/README.md) | Renegade (US) (`renegade`) | Technos Japan (Taito America license), 1986 — JOTEGO port | 2026-08-07 |
| [`jtlabrun`](cores/labrun/README.md) | Trick Trap (World?) (`tricktrp`) | Konami, 1987 — JOTEGO port | 2026-08-07 |
| [`jtmidres`](cores/midres/) | Midnight Resistance (World, set 1) (`midres`) | Data East Corporation, 1989 — JOTEGO port | 2026-08-07 |
| [`jtmikie`](cores/mikie/README.md) | Mikie (`mikie`) | Konami, 1984 — JOTEGO port | 2026-08-07 |
| [`jtmx5k`](cores/mx5k/README.md) | MX5000 (`mx5000`) | Konami, 1987 — JOTEGO port | 2026-08-07 |
| [`jtninja`](cores/ninja/README.md) | Bad Dudes vs. Dragonninja (US, revision 1) (`baddudes`)<br>Heavy Barrel (World) (`hbarrel`) | Data East Corporation, 1987–1988 — JOTEGO port | 2026-08-07 |
| [`jtoutrun`](cores/outrun/README.md) | Out Run (sitdown-upright, Rev B) (`outrun`)<br>Turbo Out Run (Out Run upgrade) (FD1094 317-0118) (`toutrun`) | Sega, 1986–1989 — JOTEGO port | 2026-08-07 |
| [`jtpaclan`](cores/paclan/) | Pac-Land (World) (`pacland`) | Namco, 1984 — JOTEGO port | 2026-08-07 |
| [`jtpang`](cores/pang/README.md) | Adventure Quiz 2 - Hatena? no Daibouken (Japan 900228) (`hatena`)<br>Block Block (World 911219 Joystick) (`block`)<br>Capcom World (Japan) (`cworld`)<br>Dokaben (Japan) (`dokaben`)<br>Dokaben 2 (Japan) (`dokaben2`)<br>Mahjong Gakuen (`mgakuen`)<br>Mahjong Gakuen 2 Gakuen-chou no Fukushuu (`mgakuen2`)<br>Pang (World) (`pang`)<br>Poker Ladies (`pkladies`)<br>Quiz Sangokushi (Japan) (`qsangoku`)<br>Quiz Tonosama no Yabou (Japan) (`qtono1`)<br>Super Marukin-Ban (Japan 911128) (`marukin`)<br>Super Pang (World 900914) (`spang`) | Capcom, 1988–1991 — JOTEGO port | 2026-08-07 |
| [`jtparoda`](cores/paroda/) | Parodius Da!: Shinwa kara Owarai e (World, set 1) (`parodius`)<br>Surprise Attack (World ver. K) (`suratk`) | Konami, 1990 — JOTEGO port | 2026-08-07 |
| [`jtpinpon`](cores/pinpon/README.md) | Konami's Ping-Pong (`pingpong`) | Konami, 1985 — JOTEGO port | 2026-08-07 |
| [`jtriders`](cores/riders/README.md) | Golfing Greats (World, version L) (`glfgreat`)<br>Lightning Fighters (World) (`lgtnfght`)<br>Sunset Riders (4 Players ver EAC) (`ssriders`)<br>Teenage Mutant Ninja Turtles: Turtles in Time (4 Players ver UAA) (`tmnt2`) | Konami, 1990–1991 — JOTEGO port | 2026-08-07 |
| [`jtroadf`](cores/roadf/README.md) | Hyper Sports (`hyperspt`)<br>Road Fighter (set 1) (`roadf`) | Konami, 1984 — JOTEGO port | 2026-08-07 |
| [`jtroc`](cores/roc/README.md) | Roc'n Rope (`rocnrope`) | Konami, 1983 — JOTEGO port | 2026-08-07 |
| [`jtrumble`](cores/rumble/README.md) | The Speed Rumbler (set 1) (`srumbler`) | Capcom, 1986 — JOTEGO port | 2026-08-07 |
| [`jts16`](cores/s16/README.md) | Ace Attacker (Japan, S16A) [FD1094 317-0060] (`aceattaca`)<br>Action Fighter (World, S16A) [FD1089A 317-0018] (`afighter`)<br>Alex Kidd: The Lost Stars (Set 2, World, S16A) [No Protection] (`alexkidd`)<br>Body Slam (World, S16) [8751 317-0015] (`bodyslam`)<br>Fantasy Zone (Rev A, World, S16A) [No Protection] (`fantzone`)<br>Major League (World, S16A) [No Protection] (`mjleague`)<br>Quartet (Rev A, 4p, World, S16A) [8751 315-5194] (`quartet`)<br>Quartet 2 (World, S16A) [No Protection] (`quartet2a`)<br>SDI: Strategic Defense Initiative (Japan, New Ver., S16A) [FD1089B 317-0027] (`sdi`)<br>Shinobi (Set 6, World, S16A) [No Protection] (`shinobi`)<br>Tetris (Set 4, Japan, S16A) [FD1094 317-0093] (`tetris`) | Sega, 1985–1988 — JOTEGO port | 2026-08-07 |
| [`jts16b`](cores/s16b/README.md) | Alien Syndrome (set 4, System 16B, unprotected) (`aliensyn`)<br>Altered Beast (set 8) (8751 317-0078) (`altbeast`)<br>Aurail (set 3, US) (unprotected) (`aurail`)<br>Bay Route (set 3, World) (FD1094 317-0116) (`bayroute`)<br>Bullet (FD1094 317-0041) (`bullet`)<br>Cotton (set 4, World) (FD1094 317-0181a) (`cotton`)<br>Cyber Police ESWAT (set 4, World) (FD1094 317-0130) (`eswat`)<br>Dunk Shot (Rev C, FD1089A 317-0022) (`dunkshot`)<br>Dynamite Dux (set 3, World) (FD1094 317-0096) (`ddux`)<br>Excite League (FD1094 317-0079) (`exctleag`)<br>Fantasy Zone II - The Tears of Opa-Opa (System 16C version) (`fantzn2x`)<br>Flash Point (set 2, Japan) (FD1094 317-0127A) (`fpoint`)<br>Golden Axe (set 6, US) (8751 317-123A) (`goldnaxe`)<br>MVP (set 2, US) (FD1094 317-0143) (`mvp`)<br>Passing Shot (World, 2 Players) (FD1094 317-0080) (`passsht`)<br>Riot City (Japan) (`riotcity`)<br>RyuKyu (Rev A, Japan) (FD1094 317-5023A) (`ryukyu`)<br>Sonic Boom (FD1094 317-0053) (`sonicbom`)<br>Sukeban Jansi Ryuko (set 2, System 16B, FD1089B 317-5021) (`sjryuko`)<br>Super League (FD1094 317-0045) (`suprleag`)<br>Time Scanner (set 2, System 16B) (`timescan`)<br>Toryumon (`toryumon`)<br>Tough Turf (set 1, US) (8751 317-0099) (`tturfu`)<br>Wonder Boy III - Monster Lair (set 6, World, System 16B) (8751 317-0098) (`wb3`)<br>Wrestle War (set 3, World) (8751 317-0103) (`wrestwar`) | Sega, 1987–2008 — JOTEGO port | 2026-08-07 |
| [`jts18`](cores/s18/README.md) | Alien Storm (World, 2 Players) (FD1094 317-0154) (`astorm`)<br>Bloxeed (Japan) (FD1094 317-0139) (`bloxeed`)<br>Clockwork Aquario (prototype) (`aquario`)<br>Clutch Hitter (US) (FD1094 317-0176) (`cltchitr`)<br>D. D. Crew (World, 3 Players) (FD1094 317-0190) (`ddcrew`)<br>Desert Breaker (World) (FD1094 317-0196) (`desertbr`)<br>Hammer Away (Japan, prototype) (`hamaway`)<br>Laser Ghost (World) (FD1094 317-0166) (`lghost`)<br>Michael Jackson's Moonwalker (World) (FD1094-8751 317-0159) (`mwalk`)<br>Shadow Dancer (World) (`shdancer`)<br>Wally wo Sagase! (rev B, Japan, 2 players) (FD1094 317-0197B) (`wwallyj`) | Sega, 1989–2021 — JOTEGO port | 2026-08-07 |
| [`jtsarms`](cores/sarms/README.md) | Hyper Dyne Side Arms (World, 861129) (`sidearms`) | Capcom, 1986 — JOTEGO port | 2026-08-07 |
| [`jtsbaskt`](cores/sbaskt/README.md) | Super Basketball (version I, encrypted) (`sbasketb`) | Konami, 1984 — JOTEGO port | 2026-08-07 |
| [`jtsectnz`](cores/sectnz/README.md) | Legendary Wings (US, rev. C) (`lwings`)<br>Section Z (US) (`sectionz`) | Capcom, 1985–1986 — JOTEGO port | 2026-08-07 |
| [`jtsf`](cores/sf/README.md) | Street Fighter (US, set 1) (`sf`) | Capcom, 1987 — JOTEGO port | 2026-08-07 |
| [`jtshanon`](cores/shanon/README.md) | Super Hang-On (sitdown-upright) (unprotected) (`shangon`) | Sega, 1987 — JOTEGO port | 2026-08-07 |
| [`jtshouse`](cores/shouse/README.md) | Bakutotsu Kijuutei (`bakutotu`)<br>Blast Off (Japan) (`blastoff`)<br>Blazer (Japan) (`blazer`)<br>Boxy Boy (World, SB2) (`boxyboy`)<br>Chou Zetsurinjin Berabowman (Japan, Rev C) (`berabohm`)<br>Dangerous Seed (Japan) (`dangseed`)<br>Dragon Spirit (new version (DS3)) (`dspirit`)<br>Face Off (Japan 2 Players) (`faceoff`)<br>Galaga '88 (`galaga88`)<br>Marchen Maze (Japan) (`mmaze`)<br>Pac-Mania (`pacmania`)<br>Pistol Daimyo no Bouken (Japan) (`pistoldm`)<br>Pro Tennis World Court (Japan) (`wldcourt`)<br>Pro Yakyuu World Stadium (Japan) (`ws`)<br>Quester (Japan) (`quester`)<br>Rompers (Japan, new version (Rev B)) (`rompers`)<br>Shadowland (YD3) (`shadowld`)<br>Splatter House (World, new version (SH3)) (`splatter`)<br>Tank Force (US, 2 Players) (`tankfrce`) | Namco, 1987–1991 — JOTEGO port | 2026-08-07 |
| [`jtsimson`](cores/simson/README.md) | Escape Kids (Asia, 4 Players) (`esckids`)<br>The Simpsons (4 Players World, set 1) (`simpsons`)<br>Vendetta (World, 4 Players, ver. T) (`vendetta`) | Konami, 1991 — JOTEGO port | 2026-08-07 |
| [`jtslyspy`](cores/slyspy/) | Boulder Dash - Boulder Dash Part 2 (World) (`bouldash`)<br>Secret Agent (World, revision 3) (`secretag`) | Data East Corporation, 1989–1990 — JOTEGO port | 2026-08-07 |
| [`jtthundr`](cores/thundr/) | Alien Sector (`aliensec`)<br>Genpei ToumaDen (`genpeitd`)<br>Hopping Mappy (`hopmappy`)<br>Metro-Cross (set 1) (`metrocrs`)<br>Rolling Thunder (rev 3) (`rthunder`)<br>Sky Kid Deluxe (set 1) (`skykiddx`)<br>The Return of Ishtar (`roishtar`)<br>Wonder Momo (`wndrmomo`) | Namco, 1985–1987 — JOTEGO port | 2026-08-07 |
| [`jttmnt`](cores/tmnt/README.md) | M.I.A. - Missing in Action (version T) (`mia`)<br>Punk Shot (US 4 Players) (`punkshot`)<br>Teenage Mutant Ninja Turtles (World 4 Players, version X) (`tmnt`)<br>Thunder Cross II (World) (`thndrx2`) | Konami, 1989–1991 — JOTEGO port | 2026-08-07 |
| [`jttoki`](cores/toki/README.md) | Cabal (World, Joystick) (`cabal`)<br>Toki (World, set 1) (`toki`) | TAD Corporation, 1988–1989 — JOTEGO port | 2026-08-07 |
| [`jttora`](cores/tora/README.md) | F-1 Dream (`f1dream`)<br>Tiger Road (US) (`tigeroad`) | Capcom, 1987–1988 — JOTEGO port | 2026-08-07 |
| [`jttrack`](cores/track/README.md) | Track & Field (`trackfld`) | Konami, 1983 — JOTEGO port | 2026-08-07 |
| [`jttrojan`](cores/trojan/README.md) | Avengers (US, rev. D) (`avengers`)<br>Trojan (US set 1) (`trojan`) | Capcom, 1986–1987 — JOTEGO port | 2026-08-07 |
| [`jttwin16`](cores/twin16/README.md) | Devil World (`devilw`)<br>Vulcan Venture (new) (`vulcan`) | Konami, 1987–1988 — JOTEGO port | 2026-08-07 |
| [`jtvigil`](cores/vigil/README.md) | Vigilante (World, Rev E) (`vigilant`) | Irem, 1988 — JOTEGO port | 2026-08-07 |
| [`jtwc`](cores/wc/README.md) | Gridiron Fight (World) (`gridiron`)<br>Tehkan World Cup (set 1) (`tehkanwc`) | Tehkan, 1985 — JOTEGO port | 2026-08-07 |
| [`jtwwfss`](cores/wwfss/README.md) | WWF Superstars (Europe) (`wwfsstar`) | Technos Japan, 1989 — JOTEGO port | 2026-08-07 |
| [`jtyiear`](cores/yiear/README.md) | Yie Ar Kung-Fu (version I) (`yiear`) | Konami, 1985 — JOTEGO port | 2026-08-07 |
| [`moomesa`](cores/moomesa/) | Bucky O'Hare (ver EAB) (`bucky`)<br>Wild West C.O.W.-Boys of Moo Mesa (FF, Konami, 1992) (`moomesa`) | Konami, 1992 — jlrh port | 2026-08-07 |
| [`mystston`](cores/mystston/README.md) | Mysterious Stones: Dr. John's Adventure (`mystston`) | Technos Japan, 1984 | 2026-08-07 |
| [`opwolf`](cores/opwolf/) | Operation Wolf (World, rev 2, set 1) (`opwolf`) | Taito, 1987 — jlrh port | 2026-08-07 |
| [`squash`](cores/squash/) | Squash (World, ver. 1.0, checksum 015aef61) (`squash`) | Gaelco, 1992 — jlrh port | 2026-08-07 |
| [`thoop`](cores/thoop/) | Thunder Hoop (ver. 1, checksum 02a09f7d) (`thoop`) | Gaelco, 1992 — jlrh port | 2026-08-07 |
| [`thoop2`](cores/thoop2/) | TH Strikes Back (non North America, version 1.0, checksum 020EB356) (`thoop2`) | Gaelco, 1994 — jlrh port | 2026-08-07 |
| [`wrally`](cores/wrally/) | World Rally Championship (version 1.0, checksum DE0D, 08 Nov 1993) (`wrally`) | Gaelco, 1993 — jlrh port | 2026-08-07 |
| [`wrally2`](cores/wrally2/) | World Rally 2: Twin Racing (version 26-06, checksum 3EDB, mask ROM version) (`wrally2a`) | Gaelco, 1995 — jlrh port | 2026-08-07 |

*This table is updated as cores are added — see each core's own README for build/hardware notes.*

## Building

Cores follow [jotego/jtcores](https://github.com/jotego/jtcores)' own JTFRAME conventions and
tooling (`jtframe`, `jtutil`, `jtsim`, `jtcore`) — just with an added neptUNO+ target. Every step
below can run as a plain command against a local toolchain, or in Docker to avoid installing one;
only synthesis (Quartus) *requires* Docker, since Quartus itself isn't something these images can
legally redistribute for local install.

All commands below were verified end to end against `1942`/`mystston` in this checkout. Two
environment gotchas apply throughout, both worth knowing before running any of them:

- **A space anywhere in the repo's own path (e.g. `.../SSD 2TB/...`) breaks jotego's native shell
  tooling** (`setprj.sh`, the `bin/jtframe` wrapper, etc. — they don't quote `$JTROOT`/`$JTFRAME`
  internally, so a path containing a space splits into multiple words and every `[ -e $BIN ]`-style
  test breaks). This alone is a strong argument for Docker over local commands here: bind-mounting
  to a fixed no-space container path (`/build`) sidesteps it entirely.
- **Docker containers must run as the host UID/GID** (`--user "$(id -u):$(id -g)"`) — without it,
  the bind-mounted repo comes up root-owned inside the container, git refuses to touch it
  ("dubious ownership"), and `jtframe` (which shells out to `git` for commit-hash macros) panics.

### Prerequisites: compiling `jtframe` / `jtutil`

`jtframe` (drives `.mra` generation, target file generation, etc.) and `jtutil` (macro/config
plumbing `jtcore` shells out to) are Go CLIs built from source, once, before anything else —
**`CGO_ENABLED=0` is required, not optional**: a normally-linked binary pulls in the host's glibc,
which is newer than what `jotego/jtcore13`'s older base image ships (confirmed directly: a
non-static build fails inside that image with `version 'GLIBC_2.34' not found`; `jotego/simulator`
happens to tolerate it, `jotego/jtcore13` does not — don't rely on that inconsistency, always build
static):

```sh
cd modules/jtframe/src/jtframe && CGO_ENABLED=0 go build .
cd modules/jtframe/src/jtutil  && CGO_ENABLED=0 go build .
```

Rebuild them (same command) whenever `modules/jtframe` is updated — both `bin/jtframe`/`bin/jtutil`
themselves and this project's own tooling check `.go` mtimes against the binary and rebuild
automatically, but a stale manually-built binary won't self-detect that.

### 1. Lint

Don't hand-roll a `verilator` invocation — a core's real macro set (`JTFRAME_MEMGEN`, per-target
clock timing, etc.) and its generated `mem_ports.inc`/`jtframe_game_ports.inc` includes only exist
once JTFRAME's own environment is initialized, so `lint-one.sh` (which does that via `jtframe
cfgstr`/`jtframe mem` before invoking Verilator) is the only supported entry point:

```sh
source modules/jtframe/bin/setprj.sh   # sets JTROOT/JTFRAME/CORES/MODULES/JTBIN + PATH
lint-one.sh <core>
```

Needs a local `verilator` install. **Docker** (no local Verilator needed) — same script, run
inside `jotego/simulator` with the whole repo bind-mounted so `setprj.sh` resolves paths correctly:

```sh
docker run --rm --entrypoint bash --user "$(id -u):$(id -g)" \
  -v "$PWD":/build -w /build \
  jotego/simulator -c 'source /build/modules/jtframe/bin/setprj.sh && lint-one.sh <core>'
```

`jotego/simulator` is jotego's own CI image — Verilator + Icarus Verilog on top of
`jotego/jtcore-base` (see JTFRAME's [`devops/linter.df`](modules/jtframe/devops/linter.df)).

### 2. Simulate (`jtsim`)

Same environment requirement as lint, plus `jtsim` must be run from inside the specific ROM set's
own `ver/<setname>/` folder (not the core's root), and needs the real MAME ROM at
`$JTROOT/rom/<setname>.rom` — it fails cleanly with a clear error if that ROM isn't present, which
is expected (ROMs are copyrighted, never bundled in this repo):

```sh
source modules/jtframe/bin/setprj.sh
cd $CORES/<core>/ver/<setname>
jtsim -mister   # or -neptunoplus, -mist, ...
```

**Docker**, same pattern as lint:

```sh
docker run --rm --entrypoint bash --user "$(id -u):$(id -g)" \
  -v "$PWD":/build -w /build \
  jotego/simulator -c 'source /build/modules/jtframe/bin/setprj.sh && cd $CORES/<core>/ver/<setname> && jtsim -mister'
```

### 3. Generate `.mra` / `.arc` from `cfg/mame2mra.toml`

`.mra` comes straight from the `jtframe` binary built above, reading each core's
`cfg/mame2mra.toml` (plus MAME's XML database for the referenced driver/sets). `--skipROM` skips
packing the actual MAME ROM data (needs real ROM zips under `$JTROOT/rom/`, same as `jtsim` above)
and just emits the `.mra` XML — drop it once you do have the ROMs available:

```sh
source modules/jtframe/bin/setprj.sh
jtframe mra <core> --verbose --skipROM
```

Same via Docker (`jotego/simulator`, same `--user`/bind-mount pattern as lint/simulate above).
Output lands in `$JTROOT/release/mra/` (jotego's own default — note this project's *own* published
releases live in `releases/mra/`, plural, one level up in naming; nothing copies between the two
automatically, this is only the raw tool's own output location).

`.arc` (the MiST-family equivalent) is then derived from that `.mra` by
[mist-devel/mra-tools-c](https://github.com/mist-devel/mra-tools-c)'s own `mra` CLI — the same
tool jotego's own release process uses (see JTFRAME's `bin/jtbin2sd`). Build it once from the
`modules/mra-tools-c` submodule:

```sh
cd modules/mra-tools-c && make -j
```

then, per ROM set:

```sh
modules/mra-tools-c/mra -z <romset>.zip -O releases/arc -A -s -a "<display name>" <core>.mra
```

### 4. Synthesize

FPGA image (`.rbf`) synthesis runs Quartus inside jotego's own per-platform Docker images —
Quartus isn't installed locally at all:

| Target | Image |
|---|---|
| MiSTer | `jotego/jtcore24` |
| MiST / SiDi / neptUNO+ | `jotego/jtcore13` |
| Pocket | `jotego/jtcore20` |

```sh
docker run --rm --entrypoint "" --user "$(id -u):$(id -g)" \
  -v "$PWD/modules":/jtcores:ro \
  -v /path/to/build:/build \
  -v "$PWD/cores/<core>/cfg":/core_cfg:ro \
  -v "$PWD/cores/<core>/hdl":/core_hdl:ro \
  jotego/jtcore13 bash -c '
    mkdir -p /build/modules /build/cores/<core>/cfg /build/cores/<core>/hdl
    cp -rp /jtcores/. /build/modules/
    cp -r /core_cfg/. /build/cores/<core>/cfg/
    cp -r /core_hdl/. /build/cores/<core>/hdl/
    cd /build && git init -q && git -c user.email=a@a -c user.name=a commit --allow-empty -q -m x
    export JTROOT=/build JTFRAME=/build/modules/jtframe CORES=/build/cores MODULES=/build/modules
    export PATH=$PATH:/build/modules/jtframe/bin
    jtcore <core> -neptunoplus --nolinter
  '
```

Verified end to end against `mystston -neptunoplus`: `Quartus II Full Compilation was successful.
0 errors, 54 warnings` → `PASS`, producing a real 1.7MB `/build/release/neptunoplus/mystston.rbf`
in ~13 minutes on this machine — that's the ballpark to expect for a single-game core; multi-game
cores (CPS1, S16B, ...) take longer.

Output lands in `/build/release/<target>/`. A core with a `syn/` override needs the matching
`-v ...cores/<core>/syn:/core_syn:ro` mount too, copied into `/build/cores/<core>/syn/` before
`jtcore` runs — same idea as the `hdl` mount above.

**Cores that share HDL/config with a sibling** (jotego's shared-hardware families — confirmed
directly: `1942`'s `cfg/files.yaml` references `gng`'s modules) need that sibling's `cfg`/`hdl`
bind-mounted too, at `/core_cfg__<dep>`/`/core_hdl__<dep>` and copied into
`/build/cores/<dep>/{cfg,hdl}/` the same way — otherwise `jtcore` fails with `Cannot resolve path
alias <dep> meaningfully`. Resolving which siblings a given core depends on isn't a one-liner (it
means reading that core's own `files.yaml`); this is exactly the piece
[arcfpga-ui](https://github.com/bmo00/arcfpga-ui) automates for you.

## Credits

- [Jose Tejada (jotego)](https://github.com/jotego) — [JTFRAME](https://github.com/jotego/jtframe)
  and [jtcores](https://github.com/jotego/jtcores), the framework and core collection this project
  builds on.
- [somhi](https://github.com/somhi) — reference work on JTFRAME-based neptUNO+ targets, used
  alongside other public sources when building this project's own neptUNO+ target.
- The MiSTer/MiST/SiDi open-source FPGA arcade community.
