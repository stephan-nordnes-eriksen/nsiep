# Linux support

Copy the file [nsiep](!nsiep/linux/nsiep) to `/usr/share/X11/xkb/symbols/` and then select nsiep as the layout in your keyboard settings.

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
