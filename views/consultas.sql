-- 01) Qual a área geral das categorias de curso com maior quantidade de novas vagas anuais?
CREATE OR REPLACE VIEW area_geral_mais_vagas AS
(
    WITH vagas_por_area_geral AS
    (
        SELECT      ger, SUM(vagas_ano) AS qtd_vagas
        FROM        categoria_curso AS Cat
                    INNER JOIN Curso AS Cur
        ON          Cat.rotulo = Cur.rotulo_categoria_curso
        GROUP BY    ger
    ),

    max_vagas AS
    (
        SELECT  MAX(qtd_vagas) AS qtd_vagas
        FROM    vagas_por_area_geral        
    )

    SELECT  ger AS area_geral, qtd_vagas
    FROM    vagas_por_area_geral
            NATURAL INNER JOIN
            max_vagas
)

/* OK */
-- Validação: Soma de 'Educação' deve corresponder à exibida na consulta anterior
SELECT      ger, SUM(vagas_ano) AS qtd_vagas
FROM        categoria_curso AS Cat
            INNER JOIN Curso AS Cur
ON          Cat.rotulo = Cur.rotulo_categoria_curso 
GROUP BY    ger
ORDER BY    qtd_vagas


-- 02) Quais os professores com habilitação em Computação que lecionam
-- ao menos um curso com modalidade remota?
CREATE OR REPLACE VIEW professores_comp_remotos AS
(
    SELECT  P.nome, P.id, D.habilitacao, C.cod_emec
    FROM    pessoa AS P
            INNER JOIN docente AS D
                ON P.id = D.id_pessoa
            INNER JOIN leciona AS L
                ON L.id_docente = D.id_pessoa
            INNER JOIN curso AS C
                ON C.cod_emec = L.cod_curso
    WHERE   C.modalidade = 'remoto'
    AND     D.habilitacao LIKE '%Computação%'
    OR      D.habilitacao LIKE '%Computacao%'
    ORDER BY P.nome
)

/* OK */
-- Validação: Cursos exibidos têm de ser remotos
SELECT  *
FROM    curso
WHERE   cod_emec IN
(
    SELECT  cod_emec
    FROM    professores_comp_remotos
)


-- 03) Qual o total de alunos de baixa renda (classes E e D) que se inscreveram em vestibulares em 2020.1?
CREATE OR REPLACE VIEW baixa_renda_2020_1_vest AS
(
    SELECT  COUNT(*) AS qtd_inscritos_baixa_renda
    FROM    candidata AS C
            INNER JOIN
            discente AS D
    ON      C.id_discente = D.id_pessoa
    WHERE   C.periodo = '2020.1'
    AND     D.renda IN ('E', 'D')
)

/* OK */
-- Validação: Devem aparecer dez colunas, com os devidos atributos.
SELECT  *
FROM    candidata AS C
        INNER JOIN
        discente AS D
ON      C.id_discente = D.id_pessoa
WHERE   C.periodo = '2020.1'
AND     D.renda IN ('E', 'D')


-- 04) Quais pessoas são simultaneamente discentes e docentes?
CREATE OR REPLACE VIEW discente_e_docente AS
(
    SELECT  P.*
    FROM    pessoa AS P
    WHERE EXISTS
    (
        SELECT  id_pessoa
        FROM    discente
        WHERE   id_pessoa = P.id
    )
    AND EXISTS
    (
        SELECT  id_pessoa
        FROM    docente
        WHERE   id_pessoa = P.id
    )
    ORDER BY P.nome ASC
)

/*  OK */
-- Validação: Resposta deve ser igual, pois uma pessoa é discente e docente se, e somente se,
-- seu identificador está na interseção das projeções em id_pessoa das tabelas Discente e Docente.
(
    SELECT  id_pessoa
    FROM    docente
)
INTERSECT
(
    SELECT  id_pessoa
    FROM    discente
)


-- 05) Quais discentes possuem simultaneamente deficiência auditiva e visual?
CREATE OR REPLACE VIEW  pcd_auditiva_visual AS
(
    SELECT  *
    FROM    discente AS Disc
    WHERE NOT EXISTS
    (
        (
            SELECT  defic
            FROM   (VALUES ('auditiva'), ('visual')) AS Aux(defic)
        )
        EXCEPT
        (
            SELECT  defic
            FROM    deficiencia
            WHERE   id_discente = Disc.id_pessoa
        )
    )
    ORDER BY Disc.id_pessoa ASC
)


/*  OK */
-- Validação: Os discentes da tabela devem corresponder àqueles que se relacionem com essas
-- duas formas de deficiência simultaneamente. Para vermos isso, façamos um JOIN.
WITH disc_auditiva_visual AS -- Possui 50 linhas
(
    (
        SELECT  Disc.id_pessoa
        FROM    discente AS Disc
                INNER JOIN
                deficiencia AS Def
        ON      Disc.id_pessoa = Def.id_discente
        WHERE   Def.defic = 'auditiva'
    )
    INTERSECT
    (
        SELECT  Disc.id_pessoa
        FROM    discente AS Disc
                INNER JOIN
                deficiencia AS Def
        ON      Disc.id_pessoa = Def.id_discente
        WHERE   Def.defic = 'visual'  
    )
)

(
    SELECT  id_pessoa
    FROM    disc_auditiva_visual
)
EXCEPT
(
    SELECT  id_pessoa
    FROM    pcd_auditiva_visual -- pcd também possui 50 linhas
)
-- Como o resultado foi vazio, a consulta está certa.

SELECT *
FROM candidata as cand
INNER JOIN curso as cur
ON cand.cod_curso = cur.cod_emec
WHERE cod_curso IN
(
SELECT cod_emec
FROM curso
WHERE id_ies_campus = 55
)


CREATE OR REPLACE VIEW qtd_baixa_renda_puc_rio AS
(
    WITH cod_puc AS
    (
        SELECT  id_emec
        FROM    ies
        WHERE   sigla = 'USP'
    ),
    
    cursos_puc AS
    (
        SELECT  cod_emec
        FROM    curso
        WHERE   id_ies_campus IN
        (
            SELECT  id_emec
            FROM    cod_puc
        )
    ),
    
    candidatos_puc_ult_vest AS
    (
        SELECT  id_discente, cod_curso, periodo, vestibular, COUNT(*) AS total_candidatos
        FROM    candidata
        WHERE   cod_curso IN
        (
            SELECT  cod_emec
            FROM    cursos_puc
        ) 
        AND         vest_status = 'espera'
        GROUP BY    id_discente, cod_curso, periodo, vestibular
    )

    SELECT COUNT(*) AS qtd_candidatos_baixa_renda_ult_vest_puc_rio
    FROM
    (
	    SELECT C.id_discente 
	    FROM candidatos_puc_ult_vest C INNER JOIN discente D
        ON C.id_discente = D.id_pessoa 
	    WHERE D.renda IN ('C', 'D', 'E') 
     ) AS candidatos_baixa_renda
)


-- 06) Quais as Instituições de Ensino Superior (IESs) e os respectivos números de candidatos nas quais se candidataram dois ou mais
-- discentes não homens para cursos de Engenharia ou de Computação?
CREATE OR REPLACE VIEW _2_mais_candidatos_nao_homens_eng_ou_comp AS
(
    WITH cursos_eng_ou_comp AS
    (
        SELECT  C.cod_emec
        FROM    curso AS C
        WHERE   nome LIKE '%Engenharia%'
        OR      nome LIKE '%engenharia%'
        OR      nome LIKE '%Computação%'
        OR      nome LIKE '%computação%'
    ),

    homens AS
    (
        SELECT  id_pessoa
        FROM    discente
        WHERE   genero = 'M'
    ),

    candidatos_eng_ou_comp_nao_homens AS
    (
        SELECT  cod_curso, COUNT(*) AS total_nao_homens
        FROM    candidata
        WHERE   cod_curso IN
        (
            SELECT  cod_emec
            FROM    cursos_eng_ou_comp
        )
        AND id_discente NOT IN
        (
            SELECT  id_pessoa
            FROM    homens
        )
        GROUP BY cod_curso
    )

    -- Para diferenciar, façamos o JOIN final à moda antiga, com produto cartesiano e seleção:
    SELECT  I.sigla AS ies, SUM(total_nao_homens) AS total_candidatos_nao_homens
    FROM    candidatos_eng_ou_comp_nao_homens AS CECNH, curso AS C, ies AS I
    WHERE   CECNH.cod_curso = C.cod_emec
    AND     C.id_ies_campus = I.id_emec
    GROUP BY I.sigla
    HAVING  SUM(total_nao_homens) >= 2
)

/* OK */
-- Validação: Exibir o join dos candidatos de engenharia com suas respectivas IESs.
WITH homens AS
(
    SELECT  id_pessoa, genero
    FROM    discente
    WHERE   genero = 'M'
),

nao_homens AS
(
    (
        SELECT  id_pessoa, genero
        FROM    discente
    )
    EXCEPT
    (
        SELECT  id_pessoa, genero
        FROM    homens
    )
) -- OK

-- SELECT  *
-- FROM    nao_homens

SELECT  I.sigla, Cur.nome, Disc.id_pessoa, Disc.genero
FROM    candidata AS Cand
        INNER JOIN nao_homens AS Disc ON
            Cand.id_discente = Disc.id_pessoa
        INNER JOIN curso AS Cur ON
            Cand.cod_curso = Cur.cod_emec
        INNER JOIN ies AS I ON
            Cur.id_ies_campus = I.id_emec
WHERE   Cur.nome LIKE '%Engenharia%'
OR      Cur.nome LIKE '%engenharia%'
OR      Cur.nome LIKE '%Computação%'
OR      Cur.nome LIKE '%computação%'
ORDER BY sigla ASC
