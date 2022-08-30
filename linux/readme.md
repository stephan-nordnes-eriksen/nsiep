# Linux support

Copy the file [nsiep](!nsiep/linux/nsiep) to `/usr/share/X11/xkb/symbols/`.

Add this to `/usr/share/X11/xkb/rules/evdev.xml`

```xml
    <layout>
      <configItem>
        <name>nsiep</name>
        <shortDescription>nsiep</shortDescription>
        <description>NSIEP Norwegian</description>
      </configItem>
      <variantList>
      </variantList>
    </layout>
```

Then, you need to log out, and log back in again for the effect to show up.

Select nsiep as the layout in your keyboard settings. Now the layout should show up and be functioning.
