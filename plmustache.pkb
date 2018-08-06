create or replace package body plmustache
as
--------------------------------------------------------------------------------
  c_re_tab constant varchar2(27 char):='{{#TABLE}}(.*?){{\/TABLE}}';
  c_re_var_esc constant varchar2(32 char):='{{([A-Z]{1}[A-Z0-9#$]{0,29}?)}}';
  c_re_var_uesc constant varchar2(34 char):='{{{([A-Z]{1}[A-Z0-9#$]{0,29}?)}}}';
  type t_vc2 is table of varchar2(4000 char);
  type t_aa is table of t_vc2 index by varchar2(30 char);
--------------------------------------------------------------------------------
  procedure render(
      i_sql_statement in         varchar2,
      i_template      in         varchar2,
      o_result        out nocopy varchar2)
  is
    l_sql varchar2(32767 char) := i_sql_statement;
    l_tpl  varchar2(32767 char) := i_template;
    l_out varchar2(32767 char);
    l_tmp varchar2(4000 char);
    l_aa t_aa;
  
  procedure query_to_aa is
    l_cursor sys_refcursor;
    l_cursor_int number;
    l_cursor_cols simple_integer := 0;
    l_cursor_desc dbms_sql.desc_tab2;
    l_typ_number number;
    l_typ_date date;
    l_typ_varchar varchar(32767);
  begin
    open l_cursor for l_sql;
    l_cursor_int := dbms_sql.to_cursor_number(l_cursor);
    dbms_sql.describe_columns2(l_cursor_int,l_cursor_cols,l_cursor_desc);
  
    -- set column names
    for i in 1..l_cursor_cols loop
      case
        when l_cursor_desc(i).col_type in (2,100,101) then
          dbms_sql.define_column(l_cursor_int,i,l_typ_number);
        when l_cursor_desc(i).col_type in (12,180,181,231) then
          dbms_sql.define_column(l_cursor_int,i,l_typ_date);
        else
          dbms_sql.define_column(l_cursor_int,i,l_typ_varchar,32767);
      end case;
    end loop;
    
    -- init associative arrays
    for i in 1..l_cursor_cols loop
      l_aa(l_cursor_desc(i).col_name):= t_vc2();
    end loop;
    
    while dbms_sql.fetch_rows(l_cursor_int) > 0 loop    
      for j in 1..l_cursor_cols loop
        l_aa(l_cursor_desc(j).col_name).extend();
        case
          when l_cursor_desc(j).col_type in (2,100,101) then
            dbms_sql.column_value(l_cursor_int,j,l_typ_number);
            l_aa(l_cursor_desc(j).col_name)(l_aa(l_cursor_desc(j).col_name).count):=to_char(l_typ_number);
          when l_cursor_desc(j).col_type in (12,180,181,231) then
            dbms_sql.column_value(l_cursor_int,j,l_typ_date);
            l_aa(l_cursor_desc(j).col_name)(l_aa(l_cursor_desc(j).col_name).count):=to_char(l_typ_date);
          else            
            dbms_sql.column_value(l_cursor_int,j,l_typ_varchar);
            l_aa(l_cursor_desc(j).col_name)(l_aa(l_cursor_desc(j).col_name).count):=l_typ_varchar;
        end case;
      end loop;
    end loop;

    dbms_sql.close_cursor(l_cursor_int);
    
    /*    
    ---CHECK DATA---
    l_tmp:=l_aa.first;    
    loop
      exit when l_tmp is null;
      for i in 1..l_aa(l_tmp).count loop
        dbms_output.put_line(l_tmp||' == '||l_aa(l_tmp)(i));
      end loop;
      l_tmp:=l_aa.next(l_tmp);
    end loop; 
    */
    
  exception when others then
    if dbms_sql.is_open(l_cursor_int) then
      dbms_sql.close_cursor (l_cursor_int);
    end if;
    raise;
  end;
  
  function get_joined_value(str in varchar2, esc in boolean) return varchar2 is
    l_out varchar2(32767 char):='';
  begin

    for i in 1..l_aa(str).count loop
      l_out:=l_out||l_aa(str)(i);
dbms_output.put_line('>>'||l_aa(str)(i));
    end loop;

    return l_out;

--  exception when no_data_found then 
--  dbms_output.put_line(SQLERRM);
--  return '';
  end;
  
  function get_single_value(str in varchar2, esc in boolean) return varchar2 is 
  begin
    if not esc then
      return l_aa(str)(1);
    else 
      return replace(replace(l_aa(str)(1),'<','&lt;'),'>','&gt;');
    end if;
  exception when no_data_found then return '';
  end;
  
  begin
    l_sql:=rtrim(trim(l_sql),';');
    
    query_to_aa;
  
    l_out:=l_tpl;   



/*
    <<section_replacement>>
    for hit in 1..regexp_count(l_tpl, c_re_tab, 1, 'in') loop
      l_tmp := regexp_substr(l_tpl, c_re_tab, 1, hit, 'in', 1);
      -- like normal replacement, but in array length loop...

--dbms_output.put_line('|'||l_tmp||'|');
--dbms_output.put_line('++'||regexp_substr(l_tmp, c_re_var_esc, 1, 1, 'in', 1));
--dbms_output.put_line('++'||regexp_count(l_tmp, c_re_var_esc));
--      <<escaped_variable_replacement>>
--      for hitx in 1..regexp_count(l_tmp, c_re_var_esc) loop
--        l_out:=regexp_replace(l_out,
--                              c_re_var_esc, 
--                              get_joined_value(
--                                regexp_substr(l_tmp, c_re_var_esc, 1, hitx, 'in', 1),
--                                false
--                              ),
--                              1,
--                              1);
--      end loop escaped_variable_replacement;
      
--      l_out:=regexp_replace(l_out, c_re_tab, get_joined_value(l_tmp), 1, 1);
    end loop section_replacement;
    dbms_output.put_line(l_out);
*/    
    
    l_tpl:=l_out;
    <<unescaped_variable_replacement>>
    for hit in 1..regexp_count(l_tpl, c_re_var_uesc) loop
      l_tmp := regexp_substr(l_tpl, c_re_var_uesc, 1, hit, 'i', 1);
      l_out:=regexp_replace(l_out, c_re_var_uesc, get_single_value(l_tmp, false), 1, 1);
    end loop unescaped_variable_replacement;
  
    <<escaped_variable_replacement>>
    for hit in 1..regexp_count(l_tpl, c_re_var_esc) loop
      l_tmp := regexp_substr(l_tpl, c_re_var_esc, 1, hit, 'i', 1);
      l_out:=regexp_replace(l_out, c_re_var_esc, get_single_value(l_tmp, true), 1, 1);   
    end loop escaped_variable_replacement;
    
    o_result:=l_out;
  end render;
--------------------------------------------------------------------------------
end plmustache;
/
