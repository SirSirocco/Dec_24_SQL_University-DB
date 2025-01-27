/* VIEWS AUXILIARES */
CREATE OR REPLACE VIEW ies_publicas AS
(
    SELECT  *
    FROM    ies
    WHERE   categ_adm LIKE '%publica%'
    OR      categ_adm LIKE '%pública%'
    OR      categ_adm LIKE '%Publica%'
    OR      categ adm LIKE '%Pública%'
);

CREATE OR REPLACE VIEW ies_privadas AS
(
    SELECT  *
    FROM    ies
    WHERE   categ_adm LIKE '%privada%'
    OR      categ_adm LIKE '%privado%'
    OR      categ_adm LIKE '%Privada%'
    OR      categ adm LIKE '%Privado%'
);

CREATE OR REPLACE VIEW discentes_em_publico AS
(
    SELECT  *
    FROM    discente
    WHERE   em_publico = true
);

CREATE OR REPLACE VIEW cursos_publicos AS
(
    SELECT  *
    FROM    curso
    WHERE   id_ies_campus IN
    (
        SELECT  id_emec
        FROM    ies_publicas 
    )
);

CREATE OR REPLACE VIEW cursos_privados AS
(
    SELECT  *
    FROM    curso
    WHERE   id_ies_campus IN
    (
        SELECT  id_emec
        FROM    ies_privadas 
    )
);

/*
1)
Um discente não pode ocupar simultaneamente duas vagas de curso de graduação vindas de
instituições de ensino superior (IES) públicas (BRASIL, 2009).
*/

-- Verificador de banco está OK
CREATE OR REPLACE VIEW valida_vaga_simultanea AS
(
    SELECT      id_discente, COUNT(*)
    FROM        candidata AS Cand INNER JOIN curso AS Cur
    ON          Cand.cod_curso = Cur.cod_emec
    WHERE       id_ies_campus IN
                (
                    SELECT  id_emec
                    FROM    ies_publicas 
                )
    GROUP BY    id_discente
    HAVING      COUNT(*) > 1
)
-- RESULTADO: OK


/*
2)
Um docente pode lecionar simultaneamente em no máximo duas instituições de ensino superior (IES)
públicas (BRASIL, 1988).
*/

-- Verificador de banco está OK
CREATE OR REPLACE VIEW valida_eh_func AS
(
    SELECT      id_docente, COUNT(*)
    FROM        eh_func
    WHERE       id_ies IN
    (
        SELECT  id_emec
        FROM    ies_publicas
    )
    GROUP BY    id_docente
    HAVING      COUNT(*) > 2 
);
-- RESULTADO: OK


-- View de inserção validada
CREATE OR REPLACE VIEW insere_eh_func AS
(
    SELECT *
    FROM eh_func AS F1
    WHERE NOT EXISTS
    (
        SELECT      F2.id_docente
        FROM        eh_func AS F2 INNER JOIN ies_publicas AS I
        ON          F2.id_ies = I.id_emec
        WHERE       F1.id_docente = F2.id_docente
        GROUP BY    F2.id_docente
        HAVING      COUNT(*) >= 2
    )
)
WITH CHECK OPTION;

INSERT INTO insere_eh_func(id_docente, id_ies, cargo) 
VALUES ('17084965300', 17969, 'ADJ')

INSERT INTO insere_eh_func(id_docente, id_ies, cargo) 
VALUES ('17084965300', 31, 'ADJ')

INSERT INTO insere_eh_func(id_docente, id_ies, cargo) 
VALUES ('17084965300', 21414, 'ADJ')
-- TESTADA: OK


/*
3)
Se a instituição de ensino superior for privada, toda vaga ofertada deverá ter modalidade AC.
*/

-- Verificador de banco está OK
CREATE OR REPLACE VIEW valida_vagas_privadas_ac AS
(
    SELECT  *
    FROM    candidata
    WHERE   cod_curso IN 
    (
        SELECT  cod_emec
        FROM    cursos_privados
    )
    AND     modalidade_vaga <> 'AC'
);
-- RESULTADO: OK


-- CODIGO DA PROCEDURE TROCANDO PUBLICAS POR AC
CREATE OR REPLACE FUNCTION trigger_bota_AC()
RETURNS TRIGGER AS $$
BEGIN
    -- Chama a procedure para ajustar a modalidade
    CALL bota_AC();  -- Alterado de PERFORM para CALL
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE bota_AC()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Atualizar a modalidade_vaga para 'AC' se o curso pertence a uma IES privada
    UPDATE candidata ca
    SET modalidade_vaga = 'AC'
    WHERE ca.modalidade_vaga IN ('PD', 'RA', 'RE') -- Modalidades que devem ser ajustadas
      AND ca.cod_curso IN (
          SELECT c.cod_emec
          FROM curso c
          JOIN ies i ON c.id_ies_campus = i.id_emec
          WHERE i.categ_adm IN ('Privada com fins lucrativos', 'Privada sem fins lucrativos')
      );
END;
$$;


/*
4)
Para se inscrever em qualquer das modalidades diferentes de AC, um discente deve ter feito seu
ensino médio integralmente em instituições de ensino públicas (aferível por meio do atributo “em_publico”).
*/
-- Verificador de banco está OK
CREATE OR REPLACE VIEW valida_cota_em_publico AS
(
    SELECT  *
    FROM    candidata
    WHERE   modalidade_vaga <> 'AC'
    AND     id_discente NOT IN 
    (
        SELECT  id_pessoa
        FROM    discentes_em_publico
    )
);
-- RESULTADO: OK


/*
5)
Para se inscrever via PD, um discente deve possuir ao menos um tipo de deficiência
(aferível por meio do atributo multivalorado “defic”).
*/
-- Verificador de banco está OK
CREATE OR REPLACE VIEW valida_pcd AS
(
    SELECT  *
    FROM    candidata AS C1
    WHERE   modalidade_vaga = 'PD'
    AND
    (
        NOT EXISTS
        (
            (
                SELECT  *
                FROM    candidata AS C2
                WHERE   C1.id_discente = C2.id_discente
                AND     C1.cod_curso = C2.cod_curso
                AND     C1.periodo = C2.periodo
                AND     C1.vestibular = C2.vestibular
            )
            EXCEPT
            (
                SELECT  *
                FROM    valida_cota_em_publico
            )
        )
        OR C1.id_discente NOT IN
        (
            SELECT  D.id_discente
            FROM    deficiencia AS D
        )
    )
);
-- RESULTADO: OK


/*
6)
Para se inscrever via RA um discente deve se autodeclarar preto, pardo ou indígena
(aferível por meio do atributo “raca”).
*/
-- Verificador de banco está OK
CREATE OR REPLACE VIEW valida_racial AS
(
    SELECT  *
    FROM    candidata AS C1
    WHERE   modalidade_vaga = 'RA'
    AND
    (
        NOT EXISTS
        (
            (
                SELECT  *
                FROM    candidata AS C2
                WHERE   C1.id_discente = C2.id_discente
                AND     C1.cod_curso = C2.cod_curso
                AND     C1.periodo = C2.periodo
                AND     C1.vestibular = C2.vestibular
            )
            EXCEPT
            (
                SELECT  *
                FROM    valida_cota_em_publico
            )
        )
        OR C1.id_discente NOT IN
        (
            SELECT  id_pessoa
            FROM    discente
            WHERE   raca IN ('preta', 'parda', 'indigena')
        )
    )
);
-- RESULTADO: OK


/*
7)
Para se inscrever via RE, um discente deve ter renda per capita familiar inferior a 1
(um) salário mínimo (aferível por meio do atributo “renda”).
*/

-- Verificador de banco está OK
CREATE OR REPLACE VIEW valida_social AS
(
    SELECT  *
    FROM    candidata AS C1
    WHERE   modalidade_vaga = 'RE'
    AND
    (
         NOT EXISTS
        (
            (
                SELECT  *
                FROM    candidata AS C2
                WHERE   C1.id_discente = C2.id_discente
                AND     C1.cod_curso = C2.cod_curso
                AND     C1.periodo = C2.periodo
                AND     C1.vestibular = C2.vestibular
            )
            EXCEPT
            (
                SELECT  *
                FROM    valida_cota_em_publico
            )
        )
        OR C1.id_discente NOT IN
        (
            SELECT  id_pessoa
            FROM    discente
            WHERE   renda = 'E'
        )
    )
);
-- RESULTADO: OK

-- Visão de inserção validada
CREATE OR REPLACE VIEW insere_social AS
(
    SELECT  *
    FROM    candidata
    WHERE   modalidade_vaga = 'RE'
    AND     id_discente IN
    (
        SELECT  id_pessoa
        FROM    discentes_em_publico
        WHERE   raca IN ('preta', 'parda', 'indigena')
    )
)
WITH CHECK OPTION;