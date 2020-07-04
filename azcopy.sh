azcopy make "<storage_account_name>.<blob>.core.windows.net/<container_name>?<SAS token>"
azcopy make "https://myazurestorage1987.blob.core.windows.net/myfirstBLOBcontainer?<SAS token>"


# upload
azcopy copy " <Source File>" "<storage_account_name>.<blob>.core.windows.net/<containername>?<SAS token>"
azcopy copy "C:\CSVFiles\CountryRegion.csv" "https://myazurestorage1987.blob.core.windows.net/myfirstblobcontainer/CountryRegion.csv?<SAS token>"


Azcopy copy "<directory on local computer>" "<storage_account_name>.<blob>.core.windows.net/<containername>/directoryname?<SAS token>"
--recursive

Azcopy copy " <root directory on local computer>\* " "<storage_account_name>.<blob>.core.windows.net/<containername>/directoryname?<SAS token>" 
--recursive

azcopy copy "C:\Adventureworks2014-install-files\*" "https://myazurestorage1987.blob.core.windows.net/myfirstblobcontainer/Adventureworks2014?<SAS Token>"





