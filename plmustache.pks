create or replace package plmustache authid current_user
as
  -- Render the template with the data from the SQL statement.
  -- @The SQL statement.
  -- @The mustache template with some tags.
  -- @The result string.
  procedure render(
      i_sql_statement in         varchar2,
      i_template      in         varchar2,
      o_result        out nocopy varchar2);
end plmustache;
/
