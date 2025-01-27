-- ### Questão 10 ###
-- ### A)
-- View 1: Candidaturas com bolsa
CREATE OR REPLACE VIEW candidaturas_bolsa AS
(
    SELECT  P.nome, P.id, C.bolsa, C.cod_curso
    FROM    pessoa AS P 
            INNER JOIN discente AS D ON
                P.id = D.id_pessoa
            INNER JOIN candidata AS C ON
                C.id_discente = D.id_pessoa
    WHERE   C.bolsa <> 'nenhum'
    AND     C.bolsa IS NOT NULL
)
-- Validada por inspeção.


-- Qual é o curso, o nome, e o número de identificação dos estudantes que se candidataram para Computação com uma
-- bolsa de estudos?
CREATE OR REPLACE VIEW candidaturas_bolsa_comp AS
(
    SELECT  C.nome AS nome_curso, C.cod_emec, E.nome AS nome_estudante, E.id
    FROM    candidaturas_bolsa AS E
            INNER JOIN
            curso AS C
    ON      cod_curso = cod_emec
    WHERE   C.nome LIKE '%Computação%'
)
-- Validada por inspeção.

-- View 2: Docentes que lecionam um curso remoto
CREATE OR REPLACE VIEW docentes_remotos AS
(
    SELECT  P.nome, P.id, Cur.cod_emec
    FROM    pessoa AS P
    JOIN    docente AS DOC  ON P.id = Doc.id_pessoa
    JOIN    leciona AS L    ON L.id_docente = Doc.id_pessoa
    JOIN    curso AS Cur    ON Cur.cod_emec = L.cod_curso
    WHERE   Cur.modalidade = 'remoto'
    ORDER BY P.nome
)

-- Encontre os docentes estrangeiros que lecionam cursos remotos.
CREATE OR REPLACE VIEW docentes_estrangeiros_remotos AS
(
    SELECT DISTINCT DR.nome, DR.id, DOC.nacionalidade
    FROM    docentes_remotos AS DR
    JOIN    docente AS DOC  ON DR.id = DOC.id_pessoa
    WHERE   nacionalidade NOT LIKE '%Brasileir%'
    OR      nacionalidade NOT LIKE '%brasileir%'
    ORDER BY DOC.nacionalidade
)

-- B)

-- insere_candidata_modalidade_renda
CREATE OR REPLACE VIEW insere_candidata_modalidade_renda AS
(
    SELECT  *
    FROM    candidata
    WHERE   id_discente IN
    (
        SELECT  id_pessoa
        FROM    discente
        WHERE   em_publico = TRUE
        AND     renda = 'E'
    )
    AND     modalidade_vaga = 'RE'
)
WITH CHECK OPTION

-- Candidatos aptos a se increverem na modalidade por renda:
SELECT  *
FROM    discente
WHERE   em_publico = TRUE
AND     renda = 'E'
/* 
    Isto é, devem ter feito o Ensino Médio integralmente em instituições públicas e
    devem pertencer à classe E.
 */

/* INSERT COM SUCESSO */

-- Tupla em discente que satisfaz ambas as condições:
('11456662881', 'F', 'indigena', 'E', TRUE)

INSERT INTO insere_candidata_modalidade_renda (id_discente, cod_curso, vest_status, periodo, bolsa, modalidade_vaga, vestibular)
VALUES
    ('11456662881', '0011A07A', 'espera', '2023.1', 'nenhum', 'RE', 'ENEM');
-- Exp.: OK
-- Act.: OK

/* UPDATE COM FALHA */

UPDATE  insere_candidata_modalidade_renda
SET     modalidade_vaga = 'AC'
WHERE   id_discente = '11456662881'
-- Exp.: NOK
-- Act.: NOK

/* INSERT COM FALHA */

-- Tupla em discente que satisfaz em_publico, mas não satisfaz renda:
('21161597580', 'F', 'amarela', 'A', 'TRUE')

INSERT INTO insere_candidata_modalidade_renda (id_discente, cod_curso, vest_status, periodo, bolsa, modalidade_vaga, vestibular)
VALUES
    ('21161597580', '0533F02A', 'espera', '2023.1', 'nenhum', 'RE', 'ENEM');
-- Exp.: NOK
-- Act.: NOK

-- Tupla em discente que satisfaz renda, mas não satisfaz em_publico:
('82520806906', 'M', 'indigena ', 'E', 'FALSE')

INSERT INTO insere_candidata_modalidade_renda (id_discente, cod_curso, vest_status, periodo, bolsa, modalidade_vaga, vestibular)
VALUES
    ('82520806906', '0533F02A', 'espera', '2023.1', 'nenhum', 'RE', 'ENEM');
-- Exp.: NOK
-- Act.: NOK
