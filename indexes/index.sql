-- A)

EXPLAIN
    SELECT  *
    FROM    local
    ORDER BY municipio

-- B)

-- B.1)

CREATE INDEX indSec_cnpj
ON ies (cnpj);

EXPLAIN
    SELECT *
    FROM    ies
    WHERE   cnpj = '00.331.801/0001-30';

-- B.2)

CREATE INDEX indSec_org_acad
ON ies (org_acad);

EXPLAIN
    SELECT *
    FROM    ies
    WHERE   org_acad = 'Universidade'
    ORDER BY org_acad;