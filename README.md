# createtables
## Creation of derived property values for IDNA

`createtables.rb` both fetches data from Unicode Consortium and calculates derived property values.

## Fetch by doing:

```
$ ./createtables.rb -fetch
```

## Calulate derived property values by doing:

```
$ ./createtables.rb 5.0.0
```

The version of Unicode to create derived property values for is to be an argument to the command. The directory must exist.

## Files

The files created are for each version of Unicode:

```
allcodepoints.txt
byscript.html
bygc.html
xmlrfc.xml
idnabis-tables.xml
iana.csv
```

### `allcodepoints.txt`

One line per codepoint.
Four fields, separated by `;`:

1. codepoint in hex
1. derived property value
1. rules in IDNA that matches
1. name of character

```
003F;DISALLOWED;;QUESTION MARK
0040;DISALLOWED;;COMMERCIAL AT
0041;DISALLOWED;AB;LATIN CAPITAL LETTER A
0042;DISALLOWED;AB;LATIN CAPITAL LETTER B
```

### `byscript`

All code points sorted by script in a table with the following columns:

1. codepoint in hex
1. character itself
1. derived property value
1. rules in IDNA that matches
1. what General Category (Gc) value in Unicode the character has
1. name of character

<TABLE border=1><TR><TH>Code(s)</TH><TH>Char</TD><TH>U-label</TH><TH>Rules</TH><TH>GC</TD><TH>Name(s)</TH></TR>
<TR><TD>U+060B</TD><TD>&#x060B;</TD><TD>DISALLOWED</TD><TD></TD><TD>Sc</TD><TD>AFGHANI SIGN</TD></TR>
<TR><TD>U+060D</TD><TD>&#x060D;</TD><TD>DISALLOWED</TD><TD></TD><TD>Po</TD><TD>ARABIC DATE SEPARATOR</TD></TR>
<TR><TD>U+060E</TD><TD>&#x060E;</TD><TD>DISALLOWED</TD><TD></TD><TD>So</TD><TD>ARABIC POETIC VERSE SIGN</TD></TR>
<TR><TD>U+060F</TD><TD>&#x060F;</TD><TD>DISALLOWED</TD><TD></TD><TD>So</TD><TD>ARABIC SIGN MISRA</TD></TR>
<TR><TD>U+0610</TD><TD>&#x0610;</TD><TD>PVALID</TD><TD>A</TD><TD>Mn</TD><TD>ARABIC SIGN SALLALLAHOU ALAYHE WASSALLAM</TD></TR>
</TABLE>

### `bygc.html`

All code points sorted by general category (Gc) in a table with the following columns:

1. codepoint in hex
1. character itself
1. derived property value
1. rules in IDNA that matches
1. what General Category (Gc) value in Unicode the character has
1. name of character

<TABLE border=1><TR><TH>Code(s)</TH><TH>Char</TD><TH>U-label</TH><TH>Rules</TH><TH>GC</TD><TH>Name(s)</TH></TR>
<TR><TD>U+0061</TD><TD>&#x0061;</TD><TD>PVALID</TD><TD>AE</TD><TD>Ll</TD><TD>LATIN SMALL LETTER A</TD></TR>
<TR><TD>U+0062</TD><TD>&#x0062;</TD><TD>PVALID</TD><TD>AE</TD><TD>Ll</TD><TD>LATIN SMALL LETTER B</TD></TR>
<TR><TD>U+0063</TD><TD>&#x0063;</TD><TD>PVALID</TD><TD>AE</TD><TD>Ll</TD><TD>LATIN SMALL LETTER C</TD></TR>
<TR><TD>U+0064</TD><TD>&#x0064;</TD><TD>PVALID</TD><TD>AE</TD><TD>Ll</TD><TD>LATIN SMALL LETTER D</TD></TR>
</TABLE>

### `xmlrfc.xml`

All code points in Unicode Character Database (UCD) format

```
0000..002C  ; DISALLOWED  # <control>..COMMA
002D        ; PVALID      # HYPHEN-MINUS
002E..002F  ; DISALLOWED  # FULL STOP..SOLIDUS
0030..0039  ; PVALID      # DIGIT ZERO..DIGIT NINE
003A..0060  ; DISALLOWED  # COLON..GRAVE ACCENT
```

### `idnabis-tables.xml`

All code points in the XML format IANA uses

```
    <record>
      <codepoint>018C-018D</codepoint>
      <property>PVALID</property>
      <description>LATIN SMALL LETTER D WITH TOPBAR..LATIN SMALL LETTER TURNED DELTA</description>
    </record>
    <record>
      <codepoint>018E-0191</codepoint>
      <property>DISALLOWED</property>
      <description>LATIN CAPITAL LETTER REVERSED E..LATIN CAPITAL LETTER F WITH HOOK</description>
    </record>
```

### `iana.csv`

All code points in CSV format that IANA uses with the following columns:

1. codepoint in hex, or start-end codepoint value
1. derived property value
1. name of character, or names of first and last character in the set

```
0000-002C,DISALLOWED,NULL..COMMA
002D,PVALID,HYPHEN-MINUS
002E-002F,DISALLOWED,FULL STOP..SOLIDUS
0030-0039,PVALID,DIGIT ZERO..DIGIT NINE
```
