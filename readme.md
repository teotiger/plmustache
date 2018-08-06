# PLMustache

## Introduction
PLMustache is a basic PL/SQL implementation of mustache templating.

See http://mustache.github.io and http://mustache.github.io/mustache.5.html

## Example
The following example is from http://mustache.github.io/mustache.5.html

```
declare
  l_out varchar2(32767 char);
begin
  plmustache.render(
    q'~select 'Chris' as name, '<b>GitHub</b>' as company from dual~',
    '* {{NAME}}
* {{AGE}}
* {{COMPANY}}
* {{{COMPANY}}}',
    l_out
  );
  dbms_output.put_line(l_out);
end;
/
```

<!--
Since SQL does not have an `BOOLEAN` data type, you can't check this values for executing sections or not. To make a loop over multiple values, use the TABLE keyword:

```
declare
  l_out varchar2(32767 char);
begin
  plmustache.render(
    q'~select 'Alexandre Dumas' as author, 'The Three Musketeers' as title, decode(level,1,'Athos',2,'Aramis',3,'Porthos') as musketeer from dual connect by level<=3~',
    '# World literature
In the novel {{TITLE}} by {{AUTHOR}} are several protagonist:
{{#TABLE}}
- {{MUSKETEER}} 
{{/TABLE}}',
    l_out
  );
  dbms_output.put_line(l_out);
end;
/
```

-->

## License
PLMustache is released under the [MIT license](https://github.com/teotiger/plmustache/blob/master/license.txt).

## Version History
Version 0.1 – July 30, 2018
* Initial release
