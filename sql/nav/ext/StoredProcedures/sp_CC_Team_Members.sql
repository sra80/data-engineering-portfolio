create procedure ext.sp_CC_Team_Members
    (
        @Team nvarchar(20),
        @User_ID nvarchar(40),
        @User_Name nvarchar(50)
    )

as

if (select isnull(sum(1),0) from ext.CC_Team_Members where [Team] = @Team and [User ID] = @User_ID) = 0

insert into ext.CC_Team_Members ([Team],[User ID],[User Name]) values (@Team,@User_ID,@User_Name)
GO

GRANT EXECUTE
    ON OBJECT::[ext].[sp_CC_Team_Members] TO [logic_app]
    AS [dbo];
GO
