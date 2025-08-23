create or alter view ext.vw_amazon_import_filelist

as

select
    id,
    file_name
from
    ext.amazon_import_filelist aif
where
    (
        aif.importTS is null
    )