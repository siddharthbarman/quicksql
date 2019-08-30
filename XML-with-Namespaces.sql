declare @xmlWithNs nvarchar(max) = N'
<addressBook xmlns="http://www.tempuri.org/addressBook.xsd">
	<entries xmlns:e="http://www.tempuri.org/addressBookProperties.xsd">
		<entry e:name="Siddharth Barman" e:email="siddharthbarman@email.com" />
		<entry e:name="Sajan Kumar" e:email="sajankumar@email.com" />
	</entries>
</addressBook>';

declare @xmlWithoutNs nvarchar(max) = N'
<addressBook>
	<entries>
		<entry name="Siddharth Barman" email="siddharthbarman@email.com" />
		<entry name="Sajan Kumar" email="sajankumar@email.com" />
	</entries>
</addressBook>';

declare @xml nvarchar(max) = @xmlWithoutNs;
declare @idoc int

exec sp_xml_preparedocument @idoc output, @xml;
select * from OPENXML(@idoc, N'/addressBook/entries/entry') 
with
(
	[name]  varchar(50),
	[email] varchar(50)
);
exec sp_xml_removedocument @idoc;

set @xml = @xmlWithNs;
exec sp_xml_preparedocument @idoc output, @xml 
select * from OPENXML(@idoc, N'/addressBook/entries/entry') 
with
(
	[name]  varchar(50),
	[email] varchar(50)
)
exec sp_xml_removedocument @idoc;

exec sp_xml_preparedocument @idoc output, @xml, N'<root xmlns:d="http://www.tempuri.org/addressBook.xsd" xmlns:e="http://www.tempuri.org/addressBookProperties.xsd"/>' ;
select * from OPENXML(@idoc, N'/d:addressBook/d:entries/d:entry') 
with
(
	[e:name]  varchar(50),
	[e:email] varchar(50)
);
exec sp_xml_removedocument @idoc;
