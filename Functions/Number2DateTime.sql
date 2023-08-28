CREATE FUNCTION [Number2DateTime] (@DateTime INT)
RETURNS DATETIME
AS
BEGIN	
	RETURN TSqlToolbox.DateTimeUtil.UDF_ConvertUtcToLocalByTimezoneIdentifier (
            'Central European Standard Time'
            ,DATEADD(ss, @DateTime, '1/1/1970 00:00:00')
        )
END

GO

