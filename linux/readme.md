# Linux support
Have a look at https://help.ubuntu.com/community/Custom%20keyboard%20layout%20definitions for a full guide.

Copy the file [nsiep](!nsiep/linux/nsiep) to `/usr/share/X11/xkb/symbols/`.

Add a layout entry into `/usr/share/X11/xkb/rules/evdev.xml`

```xml
<layout>
  <configItem>
    <name>nsiep</name>
    <shartDescription>ns</shortDescription>
    <description>NSIEP Norwegian</description>
    <languageList>
      <iso639Id>nob</iso639Id>
    </languageList>
  </configItem>
</layout>
```

Uncertain, but might need to add to `/usr/share/X11/xkb/rules/evdev.lst`:

```
ns        NSIEP Norwegian
```

Then, you need to log out, and log back in again for the effect to show up.

Now enable the setting by going to the system settings, region and language, input sources, "+" > other > NSIEP Norwegian > Add
