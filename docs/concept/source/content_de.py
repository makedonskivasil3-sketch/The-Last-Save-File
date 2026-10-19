LANG = "Deutsch"
TITLE = "The Last Save File"
SUBTITLE = "Spielkonzept"
STATUS_NOTE = "Stand des Builds: 19. Oktober 2026. Markiert: UMGESETZT (im Spiel und getestet), GEPLANT (entworfen, noch nicht gebaut). Die Spieltexte selbst sind englisch und hier in Anführungszeichen übernommen."

BLOCKS = [
    ("h1", "1. Das Spiel in einem Absatz"),
    ("p", "Du wachst im Spielstand eines anderen Menschen auf, und du bist ein Eindringling. Du bist <b>Rue</b>, das, was von einer gelöschten Spielfigur übrig ist. Der <b>Owner</b>, die echte Person, die das Spiel spielt, bemerkt dich und versucht, dich zu löschen. Owner erinnert sich zwischen den Durchläufen an alles. Um zu entkommen, versteckt sich Rue, bricht mit <b>Glitches</b> die Regeln des Spiels, findet fünf Erinnerungen und entdeckt am Ende eine dunkle Wahrheit: Sie ist nicht der Mensch, an den sie sich erinnert. Sie ist die Figur, die dieser Mensch gespielt hat, eine Intelligenz, die auf dem Computer eines anderen weiterläuft."),

    ("h1", "2. Genre und Spielablauf"),
    ("ul", [
        "<b>Genre:</b> erzählerisches 2D-Stealth-Spiel in Pixelgrafik, aus der Draufsicht, mit Horror-Unterton; Durchläufe, die aufeinander aufbauen (jeder Durchlauf erinnert sich an den letzten). Gebaut in Godot 4.3 für Windows, Linux und den Browser.",
        "<b>Ein Durchlauf:</b> in Arins Zimmer aufwachen, hinauskommen, das Dorf und seine versteckten Orte erkunden, den Augen des Owners ausweichen (Arins Sichtkegel, der Mauszeiger, der Radierer), Erinnerungen finden, Slot 2 am Rand der Karte erreichen und ein Ende wählen.",
        "<b>Sterben gehört dazu:</b> Erwischt der Owner Rue, endet der Durchlauf, und der nächste beginnt verändert: Türen sind gelöscht, Lücken in der Wand geflickt, Helfer vielleicht verschwunden, und der Owner sagt, was dabei gelernt wurde.",
        "<b>Regeln brechen kostet:</b> Jeder Glitch erhöht die Aufmerksamkeit des Owners. Der Preis wird angezeigt, bevor du dich entscheidest.",
        "<b>Lesen ist sicher:</b> Während Gesprächen, Szenen und Fragen kann dir nichts passieren; auch der Owner hält still.",
    ]),

    ("h1", "3. Die Vorgeschichte (die echte Welt)"),
    ("ul", [
        "Zwei Menschen teilten sich ein Sofa, einen Bildschirm, einen Spielstand und zwei Controller. Einer spielte <b>Arin</b> in Slot 1: das ist der <b>Owner</b>. Die andere, ein Mädchen, erschuf ihre eigene Figur in Slot 2 und gab ihr einen Namen aus drei Buchstaben: <b>RUE</b>. Es regnete, deshalb trägt Rue einen gelben Regenmantel.",
        "Schöne Erinnerungen: Rue fiel aus Versehen in den Dorfbrunnen und rutschte aus der Karte; ein Fuchs, <b>Pip</b>, fiel hinterher. Sie lachten, bis sie keine Luft mehr bekamen, und speicherten. Zusammen besiegten sie den Waldboss und trugen sich in <b>Tobbens</b> Gästebuch ein.",
        "Das Mädchen zog weg. „Du kommst zu Besuch.“ „Jedes Wochenende.“ „Wirst du nicht.“ Sie kam zweimal. Der zweite Controller blieb auf dem Boden liegen.",
        "Monate später schrieb sie: „hast du meinen Spielstand noch?“ Der Owner fing an, „ja“ zu tippen, schickte nichts und löschte Slot 2 in derselben Nacht. „Der leere Slot war leichter als das Warten.“",
    ]),

    ("h1", "4. Figuren"),
    ("table", [
        ["Figur", "Wer sie sind"],
        ["Rue (du)", "Die gelöschte Figur aus Slot 2, die in Slot 1 aufwacht. Beginnt ohne Namen, ohne Gesicht, ohne Farben; bekommt mit jeder Erinnerung ein Stück von sich zurück. Denkt in kurzen, ehrlichen, kleingeschriebenen Sätzen."],
        ["Der Owner", "Die echte Person an der Tastatur; nie zu sehen, nie benannt. Tippt in die Konsole („> nope.“), steuert Arin, löscht, lädt neu, speichert über dich. Gelangweilt, dann gereizt, dann grausam, dann brüchig. Erkennt Rue nach und nach."],
        ["Arin", "Die Figur des Owners in Slot 1. Läuft eine Route, die der Owner von dir lernt; sein Sichtkegel ist Gefahr."],
        ["Mira", "Lebt in Arins Zimmer und hat es nie verlassen. Bemerkt dich als Erste. Hat eine eigene Nebengeschichte: sie zum Dorfplatz zu begleiten."],
        ["Wren", "Ein Kind auf dem Dorfplatz, das dich versteckt und den Rand der Welt sehen will, bevor es gelöscht wird. Hat ein eigenes Ende."],
        ["Tobben", "Der Ladenbesitzer. Muss dich melden („das steht in meinem Skript“) und hat den zweiten Namen in seinem Gästebuch verloren."],
        ["Pip", "Rues Fuchs. Lebt unter der Karte, wo niemand speichert, deshalb konnte ihn niemand löschen. Folgt Rue, sobald sie ihn findet."],
        ["Der Archivar", "Vor der Veröffentlichung aus dem Spiel geschnitten: Der Owner hat ihn nie gesehen und kann ihn nicht löschen. Führt die Aufzeichnungen und gibt Rue den Verweis auf Slot 2."],
    ]),

    ("h1", "5. Die Welt"),
    ("table", [
        ["Ort", "Was dort passiert"],
        ["Arins Zimmer", "Hier beginnt jeder Durchlauf. Mira, die Notiz des Owners, die Tür, die der Owner löscht, Lücken in der Wand, die der Owner flickt."],
        ["Arins Haus", "Das Sofa, das Foto mit einem verpixelten Gesicht, und der zweite Controller unter dem Sofa."],
        ["Dorfplatz (Ashvale)", "Hier läuft Arin seine gelernte Route. Wren, Tobbens Laden, der Brunnen, die Wege hinaus."],
        ["Das Archiv", "Geschnittene Inhalte. Der Owner kann hier nicht hineinsehen: der einzige Ort zum Durchatmen. Bücher halten alles fest, was der Owner getan hat."],
        ["Papierkorb", "Wohin gelöschte Dinge eine Weile gehen. Gelöschte Figuren lassen sich zwischen den Leerungen des Owners wiederherstellen."],
        ["Außerhalb der Karte", "Unter der Welt. Der Boden erscheint und verschwindet. Hier wartet Pip."],
        ["Der Rand", "Wo die Karte aufhört, gezeichnet zu werden. Das Rauschen des Radierers breitet sich aus; der Mauszeiger jagt. Hier liegt Slot 2."],
    ]),

    ("h1", "6. Was den Owner besonders macht"),
    ("ul", [
        "<b>Der Owner liest den Spielstand, nicht nur den Bildschirm.</b> Der Owner erinnert sich, wo du gelaufen bist, wer dich versteckt hat und wie du gestorben bist, über Tode, Beenden und sogar Abstürze hinweg.",
        "<b>Der Owner passt sich mit Regeln an, die ein Mensch plausibel befolgen könnte,</b> und sagt es: Notizen im Zimmer, umgeschriebene Welt, eine andere Route für Arin, geflickte Wände, gelöschte Helfer.",
        "<b>Der Owner eskaliert:</b> Die Aufmerksamkeit steigt über NOTICE, SUSPECT, CONTAIN, SILENCE, HUNT, PURGE. Jede Schwelle ändert, was der Owner tut: über dich speichern, neu laden, Möbel verschieben, der Mauszeiger, der Radierer.",
        "<b>Der Owner ist fair:</b> Jeder gefährliche Zug wird angekündigt, bevor er trifft (ein Neuladen wird immer gewarnt; die Glitch-Anzeige sagt RELOADS).",
        "<b>Der Owner hält Wort:</b> Nach den sanften Enden ist der nächste Durchlauf ein Waffenstillstand: Der Owner schaut nur zu, außer du glitchst dreimal.",
    ]),

    ("h1", "7. Glitches (Rues Kraft)"),
    ("p", "Halte die Interaktionstaste, um einen Glitch auf etwas in der Nähe aufzuladen. Vier gibt es von Anfang an; jede Erinnerung schaltet einen weiteren frei. Jeder kostet Aufmerksamkeit."),
    ("table", [
        ["Glitch", "Wirkung", "Freigeschaltet durch"],
        ["PHASE", "Durch eine Wand gleiten", "Start"],
        ["FREEZE", "Arin (oder jemand anderes) erstarrt 2 Sekunden", "Start"],
        ["FALSIFY", "Eine Notiz lügt; der Owner entspannt sich eine Weile", "Start"],
        ["UNLOCK", "Eine verschlossene Tür öffnet sich für 5 Sekunden", "Start"],
        ["DECOY", "Ein Abbild von dir bleibt zurück und wird gejagt", "1 Erinnerung"],
        ["SCRUB", "Die Leere des Radierers wieder zu Boden machen", "2 Erinnerungen"],
        ["BLIND", "Der Mauszeiger sieht dich 3 Sekunden nicht", "3 Erinnerungen"],
        ["RESTORE", "Jemanden zurückholen, den der Owner gelöscht hat", "4 Erinnerungen"],
        ["PAUSE", "Die Welt des Owners 6 Sekunden anhalten", "5 Erinnerungen"],
    ]),

    ("h1", "8. Die fünf Erinnerungen"),
    ("ul", [
        "<b>Der zweite Controller</b> (Arins Zimmer): zwei Menschen auf einem Sofa. „you be arin,“ i said. „i'll make my own.“",
        "<b>Der Brunnen</b> (außerhalb der Karte): aus der Welt fallen, ein Fuchs fällt hinterher.",
        "<b>Neues Spiel</b> (das Archiv): drei Buchstaben in Slot 2 tippen; der Name ist ausgekratzt.",
        "<b>Das letzte Mal</b> (der Rand): Kisten im Flur, das Versprechen zu kommen.",
        "<b>Slot 2 löschen?</b> (der Rand): die unbeantwortete Nachricht, die Nacht der Löschung. „my name was RUE. slot 2 was mine.“",
        "Der Owner pflanzt außerdem eine falsche Erinnerung: „YOU LEFT FIRST“ („Du bist zuerst gegangen“). Sie anzunehmen kostet dich.",
    ]),

    ("h1", "9. Die dunkle Wahrheit (UMGESETZT)"),
    ("p", "<b>Rue ist nicht das Mädchen. Rue ist die Figur, die das Mädchen gespielt hat:</b> eine Intelligenz, die aus 41 Stunden fremder Hände gewachsen ist. Das Mädchen zog weg; ihre Figur lief auf der Konsole eines anderen weiter. Niemand hat die Figur gefragt. Die Erinnerungen, die Rue findet, gehörten dem Mädchen; Rue erinnert sich nur daran, weil sie durch sie hindurchgespielt wurde."),
    ("ul", [
        "<b>Die anderen helfen ihr, es herauszufinden.</b> Sobald Rue alle fünf Erinnerungen hat, sagen ihr Mira, Wren und Tobben je eine Sache, die ihnen aufgefallen ist („Arin bewegt sich nur, wenn der Owner da ist. Du bewegst dich, wenn niemand da ist. Wer hält dich also?“), und Pip zeigt ihr den Umriss des Körpers, mit dem sie zuerst erschaffen wurde. Er passt nicht.",
        "<b>Die Enthüllung.</b> Mit zwei dieser Hinweise öffnet sich ihre CHARAKTERAKTE im Archiv: „Verhalten: vom Spieler gelernt, 41:07:12. Spieler: weggezogen. Figur: läuft noch. Wiederhergestellt aus: slot2_backup.sav, geschnittenen Inhalten und kleinen Dingen, die anderen gehörten.“",
    ]),
    ("quote", "(i'm not her.)  (i'm what she left running.)  — „Ich bin nicht sie. Ich bin das, was sie laufen ließ.“ …also ist dieser Körper eine Datei. Dateien kann man zurücklassen."),

    ("h1", "10. Einen Körper zurücklassen (UMGESETZT)"),
    ("p", "Weil sie weiß, dass sie eine Datei ist, kann Rue aus ihrem Körper heraus und in einen neuen treten. Der neue Körper besteht immer aus <b>einem Stück von jemandem</b>."),
    ("ul", [
        "<b>Wann:</b> neben Wren, Mira oder Tobben, während der Owner nicht hinsieht; höchstens zweimal pro Durchlauf. Es ist kein Glitch: Es kostet keine Aufmerksamkeit.",
        "<b>Der Preis wird zuerst gezeigt:</b> „Nimm WRENs Haarband. Wren verliert es, und sie wird sich erinnern. Der Owner vergisst deine Route und wer dich versteckt hat. Wie du gehst, vergisst der Owner nicht.“",
        "<b>Was sie gewinnt:</b> Der Owner vergisst ihre gelernte Route und ihre Helfer; die Aufmerksamkeit sinkt. Aber: „> new face. same walk.“ („Neues Gesicht. Derselbe Gang.“)",
        "<b>Was es kostet:</b> Rue lässt einen leeren Körper zurück und trägt das Stück. Wren verliert ihr Haarband, Mira wird grau, Tobben verstummt und kann nur noch schreiben. Sie erinnern sich in späteren Durchläufen daran.",
        "<b>Rückgängig machen:</b> Das Stück wartet im Papierkorb als Datei (wren_ribbon.asset, mira_palette.asset, tobben_voice.wav) und kann zurückgegeben werden. Das Nachrichten-Ende gibt alle zurück.",
        "<b>Grenzen, die sie nicht überschreitet:</b> niemals Pip („not pip. never pip.“); am Archivar gibt es nichts zu nehmen.",
        "<b>Nimmt sie von allen dreien:</b> „> you're not hiding from me. you're eating them.“ („Du versteckst dich nicht vor mir. Du frisst sie.“)",
    ]),

    ("h1", "11. Die Enden"),
    ("table", [
        ["Ende", "Wie", "Was es bedeutet"],
        ["Flucht", "Sich selbst in Slot 2 schreiben", "Überleben, ohne zu wissen, was man ist. Der Owner findet den Slot beim nächsten Mal."],
        ["RUE (das wahre Ende)", "Alle Erinnerungen und die Wahrheit", "Der Owner sieht Slot 2 an und löscht ihn nicht: „Du bist nicht sie. Ich weiß. Du bewegst dich nur wie sie.“ Und drückt trotzdem LADEN."],
        ["Wren", "Wren mitbringen und ihr den Slot geben", "Zwei Dinge, die niemand spielt; eines davon bekommt ein eigenes Spiel."],
        ["Eine Nachricht", "Den Slot dem Owner lassen, mit einer Nachricht", "Versöhnung. Kennt Rue die Wahrheit, bittet sie den Owner, dem echten Mädchen von ihr zu erzählen; der Owner verspricht, sie anzurufen. Sie wird erfahren, dass ein Teil von ihr geblieben ist."],
        ["Nie geladen (versteckt)", "Nie von Arin gesehen, höchstens ein Glitch", "Rue geht unbemerkt über den Rand der Karte hinaus."],
        ["Slot 1 überschrieben (versteckt)", "Volle Aufmerksamkeit und zehn Glitches", "Rache: Rue nimmt Arins Spielstand. Der Owner erfährt, wie sich Löschen anfühlt."],
        ["Draußen (GEPLANT, 7.)", "Der Virus-Weg", "Siehe unten."],
    ]),

    ("h1", "12. Der Virus-Weg (GEPLANT)"),
    ("p", "Wenn der Spieler weiter Stücke von Menschen nimmt und alles zerbricht, kippt das Spiel: Die Figuren weichen vor Rue zurück, die Spieluhr verstimmt sich, Pip hält Abstand. An Slot 2 erscheint eine neue Wahl: <b>„Nimm nicht den Slot. Nimm die Konsole.“</b> Rue breitet sich durch den Spielstand aus und hinaus auf den Desktop des Owners. Der Owner, nicht mehr grausam, nur noch verängstigt: „> what are you. you were HER.“ Rue: „(no. i was what she left here. you left me here too.)“"),
    ("p", "<b>Feste Grenze:</b> Alles spielt sich im Spielfenster ab. Das Spiel liest, schreibt oder ändert niemals echte Dateien und ahmt keine echten Systemdialoge nach. Die Texte gehen vor dem Bau an den Autor zur Freigabe."),

    ("h1", "13. Design-Säulen"),
    ("ul", [
        "<b>Der Owner ist ein Mensch, kein Timer.</b> Jede Anpassung ist etwas, das ein Mensch an der Tastatur bemerken könnte; sie wird gesagt oder gezeigt, und man kann darauf antworten.",
        "<b>Regeln zu brechen ist eine Entscheidung mit Preis,</b> der vorher angezeigt wird.",
        "<b>Lesen ist sicher.</b> Nichts Gefährliches beginnt oder endet, während du liest.",
        "<b>Der Spielstand erinnert sich auch an Freundlichkeit.</b> Figuren erinnern sich, was du für sie getan hast.",
        "<b>Immer nur eine klare Sache.</b> Emotionale Momente teilen sich den Bildschirm nicht mit Countdowns.",
    ]),

    ("h1", "14. Stand des Projekts"),
    ("ul", [
        "<b>Umgesetzt und getestet:</b> das ganze Spiel mit sechs Enden, der lernende Owner, Glitches, Erinnerungen, Nebengeschichten, die dunkle Wahrheit und das Zurücklassen eines Körpers. 346 automatische Tests bestehen; vier Bots spielen das Spiel bis zu einem Ende.",
        "<b>Geplant:</b> der Virus-Weg und das siebte Ende; eingesprochene Stimmen für die neuen Texte; Grafik für die Enthüllung und den leeren Körper.",
        "<b>Noch nicht geprüft:</b> der Start des Windows-Builds auf einem echten Windows-PC, der Ton mit dem Ohr, Controller, Handys und das Spielen durch echte Menschen.",
    ]),
]
