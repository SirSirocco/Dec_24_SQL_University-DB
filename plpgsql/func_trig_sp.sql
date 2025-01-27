-- A.1)

CREATE OR REPLACE FUNCTION cursos_oferecidos_universidade(universidade TEXT)
RETURNS TABLE(cursos_oferecidos TEXT) AS
$$
    BEGIN
        RETURN  QUERY
        SELECT  C.nome::TEXT AS cursos_oferecidos  -- Aqui convertemos explicitamente para 'text'
        FROM    curso AS C
                INNER JOIN
                ies AS I
        ON      C.id_ies_campus = I.id_emec
        WHERE   I.nome = universidade
        OR      I.sigla = universidade
        ORDER BY C.nome ASC;
    END;
$$ LANGUAGE plpgsql;

-- TESTE: 
SELECT * FROM cursos_oferecidos_universidade('Faculdade de Botucatu (FDB)')

-- Obtivemos o id_emec da universidade por inspeção e depois realizamos:
SELECT  * 
FROM    curso
where   id_ies_campus = '17593'

-- Exp.:
{
    Engenharia têxtil
    Gestão estratégica
    Programas interdisciplinares abrangendo negócios, administração e direito
}
-- Act.:
{
    Engenharia têxtil
    Gestão estratégica
    Programas interdisciplinares abrangendo negócios, administração e direito
}

-- A.2)

CREATE OR REPLACE FUNCTION qtd_universidades_municipio(municipio TEXT, uf TEXT)
RETURNS INTEGER AS
$$
    DECLARE total_universidades INTEGER;
    BEGIN
	    SELECT  COUNT(*) INTO total_universidades
	    FROM    campus 
	    WHERE   uf = uf_local
        AND     municipio = municipio_local;
	    RETURN  total_universidades;
    END;
$$ LANGUAGE plpgsql;

-- TESTE:
SELECT * FROM qtd_universidades_municipio('Rio de Janeiro', 'RJ')

-- Contamos 18 valores nesta tabela:
SELECT  * 
FROM    campus
WHERE   uf_local ='RJ'
AND     municipio_local='Rio de Janeiro'

-- Exp.: 18
-- Act.: 18

-- B)

CREATE OR REPLACE PROCEDURE bota_AC()
AS $$
    BEGIN
        -- Atualizar a modalidade_vaga para 'AC' se o curso pertence a uma IES privada
        UPDATE candidata AS CA
        SET     modalidade_vaga = 'AC'
        WHERE   CA.modalidade_vaga IN ('PD', 'RA', 'RE') -- Modalidades que devem ser ajustadas
        AND     CA.cod_curso IN
        (
            SELECT  C.cod_emec
            FROM    curso AS C
            JOIN    ies AS I
            ON      C.id_ies_campus = I.id_emec
            WHERE   I.categ_adm IN ('Privada com fins lucrativos', 'Privada sem fins lucrativos')
        );
    END;
$$ LANGUAGE plpgsql;

-- TESTE:
CREATE OR REPLACE VIEW candidaturas_cursos_privados AS
(
    SELECT  *
    FROM    candidata
    WHERE   cod_curso IN
    (
        SELECT  cod_emec
        FROM    cursos_privados
    )
);

UPDATE  candidaturas_cursos_privados
SET     modalidade_vaga = 'RE';

CALL bota_AC();


-- C)

CREATE OR REPLACE FUNCTION verifica_e_insere_local()
RETURNS TRIGGER AS
$$
    BEGIN
        -- Verifica se a combinação de UF e município já existe
        IF NOT EXISTS
        (
            SELECT  * 
            FROM    local 
            WHERE   uf = NEW.uf_local
            AND     municipio = NEW.municipio_local
        ) THEN
            -- Insere o local na tabela local
            INSERT INTO local (uf, municipio) 
            VALUES (NEW.uf_local, NEW.municipio_local);
        END IF;
        RETURN NEW; -- Continua a operação de inserção em Campus
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER trg_verifica_e_insere_local
    BEFORE INSERT ON campus
    FOR EACH ROW
        EXECUTE FUNCTION verifica_e_insere_local();

-- TESTE:

/* VIEWS AUXLIARES */
-- Municipios do RJ que começam com 'M'
CREATE OR REPLACE VIEW municipios_rj_m AS
(
    SELECT  *
    FROM    local
    WHERE   municipio LIKE 'M%'
    AND     uf = 'RJ'
    ORDER BY municipio
);

-- Campi localizados no estado RJ
CREATE OR REPLACE VIEW campi_rj AS
(
    SELECT  *
    FROM    campus
    WHERE   uf_local = 'RJ'
    ORDER BY id_ies
);

/* TESTE 1 */
-- Exibir estado de Local e de Campus antes da inserção, de modo a apontar que
-- não existe o municipio "Milmandia"
SELECT * FROM municipios_rj_m;
SELECT * FROM campi_rj;

-- Inserir valor em Campus
INSERT INTO Campus (id_ies, uf_local, municipio_local)
VALUES (528,'RJ','Milmandia'); -- 528 é o id_emec da PUC-Rio

-- Reverificar Local e Campus
SELECT * FROM municipios_rj_m;
SELECT * FROM campi_rj;

/* TESTE 2 */
-- Inserir novamente outro campus nesse município e verificar que
-- não há duplicidade na inserção
INSERT INTO Campus (id_ies, uf_local, municipio_local)
VALUES (586,'RJ','Milmandia'); -- 586 é o id_emec da UFRJ

-- Reverificar Local e Campus
SELECT * FROM municipios_rj_m;
SELECT * FROM campi_rj;
