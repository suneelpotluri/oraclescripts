set pages 50000
set markup html on spool on;
spool APPS_TS_MEDIA.html;
set echo on;
variable id number;
begin
  declare
  name varchar2(100);
  descr varchar2(500);
  obj_id number;
  begin
  name:='APPSTSMEDIA';
  descr:='APPS_TS_MEDIA Segment Advisor1';

  dbms_advisor.create_task (
    advisor_name     => 'Segment Advisor',
    task_id          => :id,
    task_name        => name,
    task_desc        => descr);

  dbms_advisor.create_object (
    task_name        => name,
    object_type      => 'TABLESPACE',
    attr1            => 'APPS_TS_MEDIA',
    attr2            => NULL,
    attr3            => NULL,
    attr4            => NULL,
    attr5            => NULL,
    object_id        => obj_id);

  dbms_advisor.set_task_parameter(
    task_name        => name,
    parameter        => 'recommend_all',
    value            => 'TRUE');

  dbms_advisor.execute_task(name);
  end;
end; 
/

SELECT f.task_name,f.impact,
o.type AS object_type,
o.attr1 AS schema,
o.attr2 AS object_name,
f.message,
f.more_info
FROM dba_advisor_findings f
JOIN dba_advisor_objects o ON f.object_id = o.object_id AND f.task_name = o.task_name
WHERE f.task_name IN ('APPSTSMEDIA')
ORDER BY f.task_name, f.impact DESC;
set markup html off spool off;
spool off;
