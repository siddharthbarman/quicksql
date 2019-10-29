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

-- Parsing XML without namespaces
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

-- Reading XML with namespaces incorrectly
set @xml = @xmlWithNs;
exec sp_xml_preparedocument @idoc output, @xml 
select * from OPENXML(@idoc, N'/addressBook/entries/entry') 
with
(
	[name]  varchar(50),
	[email] varchar(50)
)
exec sp_xml_removedocument @idoc;

-- Reading XML with namespaces correctly
exec sp_xml_preparedocument @idoc output, @xml, N'<root xmlns:d="http://www.tempuri.org/addressBook.xsd" xmlns:e="http://www.tempuri.org/addressBookProperties.xsd"/>' ;
select * from OPENXML(@idoc, N'/d:addressBook/d:entries/d:entry') 
with
(
	[e:name]  varchar(50),
	[e:email] varchar(50)
);
exec sp_xml_removedocument @idoc;

-- Reading XML with namespaces correctly but renaming the columns and reading the node text
set @xmlWithNs = N'
<addressBook xmlns="http://www.tempuri.org/addressBook.xsd">
    <entries xmlns:e="http://www.tempuri.org/addressBookProperties.xsd">
        <entry e:id="1" e:email="siddharthbarman@email.com">Siddharth Barman</entry>
        <entry e:id="2" e:email="sajankumar@email.com">Sajan Kumar</entry>
    </entries>
</addressBook>';

exec sp_xml_preparedocument @idoc output, @xmlWithNs, N'<root xmlns:d="http://www.tempuri.org/addressBook.xsd" xmlns:e="http://www.tempuri.org/addressBookProperties.xsd"/>' ;

select * from OPENXML(@idoc, N'/d:addressBook/d:entries/d:entry') 
with
(
    ID int '@e:id',
    FullName varchar(50) 'text()',
	EmailID varchar(50) '@e:email'
);
exec sp_xml_removedocument @idoc;    