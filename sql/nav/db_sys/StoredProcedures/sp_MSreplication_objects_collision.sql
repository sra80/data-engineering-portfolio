CREATE procedure db_sys.sp_MSreplication_objects_collision

as

set nocount on

declare @t table (article nvarchar(64), publication nvarchar(64), art_count int, line_no int)
declare @s table (article nvarchar(64), publications nvarchar(max), art_count int)

insert into @t (article, publication, art_count, line_no)
select
    article,
    publication,
    art_count,
    line_no
from
    (
    select 
        *,
        count(1) over (partition by article) art_count,
        row_number() over (partition by article order by publication) line_no
    from
        (
            select
            *,
            row_number() over (partition by publication, article order by publication) r
        from
            [dbo].[MSreplication_objects]
        ) a
    where
        a.r = 1
    ) b

;with n (article, publications, art_count, line_no) as
    (
        select
            article,
            convert(nvarchar(max),publication),
            art_count,
            line_no
        from
            @t
        where
            line_no = 1

        union all

        select
            n.article,
            convert(nvarchar(max),concat(n.publications,case when n.art_count = n.line_no+1 then ' and ' else ', ' end,t.publication)),
            n.art_count,
            n.line_no + 1
        from
            n
        join
            @t t
        on
            n.article = t.article
        where
            n.line_no < n.art_count
        and t.line_no = n.line_no + 1
        and t.line_no > 1
    )

insert into @s (article, publications, art_count)
select
    article,
    publications,
    art_count
from
    n
where
    art_count = line_no
and art_count > 1

merge db_sys.MSreplication_objects_collision t
using @s s
on (t.article = s.article and t.publications = s.publications and t.resolved is null)
when not matched by target then 
    insert (article, publications, issue_notification)
    values (s.article, s.publications, 1)
when matched then update set
    t.issue_notification = case when datediff(minute,first_notification,getutcdate()) >= 30 and notification_count < 10 then 1 else 0 end
when not matched by source then update set
    t.resolved = getutcdate();
GO
