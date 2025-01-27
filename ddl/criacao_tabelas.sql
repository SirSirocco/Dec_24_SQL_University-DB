CREATE TABLE IES (
    id_emec         INT,
    nome            VARCHAR(255)    UNIQUE,
    sigla           VARCHAR(20),
    email           VARCHAR(255),
    ci              INT             CHECK (1 <= ci AND ci <= 5),
    credenciamento  VARCHAR(100),
    cnpj            CHAR(18),
    categ_adm       VARCHAR(100),
    org_acad        VARCHAR(100),
    situacao        VARCHAR(100),

    CONSTRAINT      PK_ies          PRIMARY KEY (id_emec)
);


CREATE TABLE Local (
    uf           CHAR(2)         CHECK (uf IN ('AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO', 'Remoto')),
    municipio    VARCHAR(255),

    CONSTRAINT   PK_local        PRIMARY KEY (uf, municipio)
);


CREATE TABLE Campus (
    id_ies          INT,
    uf_local        CHAR(2),
    municipio_local VARCHAR(255),

    CONSTRAINT  PK_campus           PRIMARY KEY (id_ies, uf_local, municipio_local),
    CONSTRAINT  FK_campus_ies       FOREIGN KEY (id_ies)                    REFERENCES IES(id_emec),
    CONSTRAINT  FK_campus_local     FOREIGN KEY (uf_local, municipio_local) REFERENCES Local(uf, municipio)
);


CREATE TABLE Categoria_Curso (
    ger     VARCHAR(255),
    rotulo  VARCHAR(255)
);
/* Adicionando PK via ALTER TABLE */
ALTER TABLE Categoria_Curso ADD CONSTRAINT PK_categoria_curso PRIMARY KEY (rotulo);


CREATE TABLE Curso (
    vagas_ano               INT                         CHECK (vagas_ano >= 0),
    enade                   INT                         CHECK (1 <= enade AND enade <= 5),
    nome                    VARCHAR(255), 
    cod_emec                CHAR(20),
    modalidade              CHAR(10)                    CHECK (modalidade IN ('presencial', 'híbrido', 'remoto')),
    grau                    CHAR(12)                    CHECK (grau IN ('bacharelado', 'licenciatura', 'tecnólogo')),
    situacao                CHAR(15),                   CHECK (situacao IN ('ativo', 'em extinção', 'extinto')),
    rotulo_categoria_curso  VARCHAR(255),
    uf_campus               CHAR(2),
    municipio_campus        VARCHAR(255),
    id_ies_campus           INT,

    CONSTRAINT      PK_curso                     PRIMARY KEY (cod_emec),
    CONSTRAINT      FK_curso_campus              FOREIGN KEY (uf_campus, municipio_campus, id_ies_campus)   REFERENCES Campus(uf_local, municipio_local, id_ies),
    CONSTRAINT      FK_curso_categoria_curso     FOREIGN KEY (rotulo_categoria_curso)                       REFERENCES Categoria_Curso(rotulo)
);


CREATE TABLE Pessoa (
    id          CHAR(16), -- CHAR(16) por causa do ID Lattes
    nome        VARCHAR(255)    NOT NULL,

    CONSTRAINT  PK_pessoa       PRIMARY KEY (id)
);


CREATE TABLE Docente ( -- estende Pessoa
    id_pessoa       CHAR(16),
    titulo          CHAR(3)             CHECK (titulo IN ('EFI','EFC','EMC','ESC','MES','DOC','PHD')),   
    ano_conclusao   CHAR(6),
    email           VARCHAR(255),
    cnpq            CHAR(2)             CHECK (cnpq IN ('1A', '1B', '1C', '1D', '2', 'NA', 'SR')),
    habilitacao     VARCHAR(100),
    nacionalidade   VARCHAR(100),

    CONSTRAINT      PK_docente          PRIMARY KEY (id_pessoa),
    CONSTRAINT      FK_docente_pessoa   FOREIGN KEY (id_pessoa)   REFERENCES Pessoa(id)
);


CREATE TABLE Discente ( -- estende Pessoa
    id_pessoa   CHAR(16),
    genero      CHAR(1)             CHECK (genero   IN ('M', 'F', 'N', 'O')),
    raca        CHAR(10)            CHECK (raca     IN ('branca', 'preta', 'parda', 'amarela', 'indigena', 'outra')),
    renda       CHAR(1)             CHECK (renda    IN ('A', 'B', 'C', 'D', 'E')),
    em_publico  BOOLEAN,

    CONSTRAINT  PK_discente         PRIMARY KEY (id_pessoa),
    CONSTRAINT  FK_discente_pessoa  FOREIGN KEY (id_pessoa)     REFERENCES Pessoa(id)
);


CREATE TABLE Deficiencia (
    id_discente     CHAR(20),
    defic           CHAR(20)                    CHECK (defic IN ('auditiva', 'intelectual', 'motora ou física', 'visual')),

    CONSTRAINT      PK_deficiencia              PRIMARY KEY (defic, id_discente),
    CONSTRAINT      FK_deficiencia_discente     FOREIGN KEY (id_discente)   REFERENCES Discente(id_pessoa)
);


/* TABELAS ORIGINADAS DE RELACIONAMENTOS */
CREATE TABLE candidata (
    id_discente     CHAR(16),
    cod_curso       CHAR(20),
    vest_status     CHAR(15)            CHECK (vest_status      IN ('matrícula', 'reprovação', 'espera', 'desistência')),
    periodo         CHAR(6),
    bolsa           CHAR(20)            CHECK (bolsa            IN ('ProUni', 'FIES', 'Institucional', 'Nenhuma')),
    modalidade_vaga CHAR(2),            CHECK (modalidade_vaga  IN ('AC', 'PD', 'RA', 'RE'))
    vestibular      CHAR(7)             CHECK (vestibular       IN ('ENEM', 'Proprio')),

    CONSTRAINT      PK_candidata                 PRIMARY KEY (cod_curso, id_discente, periodo, vestibular),
    CONSTRAINT      FK_candidata_discente        FOREIGN KEY (id_discente)      REFERENCES Discente(id_pessoa),
    CONSTRAINT      FK_candidata_curso           FOREIGN KEY (cod_curso)        REFERENCES Curso(cod_emec)
);


CREATE TABLE eh_func(
    id_docente  CHAR(16),
    id_ies      INT,
    cargo       char(6)             CHECK (cargo IN ('SUBS', 'ADJ_A', 'ASSOC', 'ASSIST', 'ADJ', 'TIT', 'OUTRO')),

    CONSTRAINT  PK_eh_func          PRIMARY KEY (id_docente, id_ies),
    CONSTRAINT  FK_eh_func_docente  FOREIGN KEY (id_docente)            REFERENCES Docente(id_pessoa),
    CONSTRAINT  FK_eh_func_ies      FOREIGN KEY (id_docente)            REFERENCES IES(id_emec)
);


CREATE TABLE leciona (
    id_docente      CHAR(16),
    cod_curso       CHAR(20),

    CONSTRAINT      PK_leciona              PRIMARY KEY (id_docente, cod_curso)
);
/* Adicionando FKs via ALTER TABLE */
ALTER TABLE leciona ADD CONSTRAINT  FK_leciona_docente  FOREIGN KEY (id_docente)    REFERENCES Docente(id_pessoa);
ALTER TABLE leciona ADD CONSTRAINT  FK_leciona_curso    FOREIGN KEY (cod_curso)     REFERENCES Curso(cod_emec);


CREATE TABLE sai (
    id_discente     CHAR(16),
    cod_curso       CHAR(20),
    periodo         CHAR(6),
    disc_status     CHAR(12)         CHECK (disc_status IN ('abandono', 'conclusão', 'jubilamento', 'troca')),

    -- Supomos que so se sai uma vez, por isso periodo nao compoe a PK
    CONSTRAINT      PK_sai              PRIMARY KEY (id_discente, cod_curso),
    CONSTRAINT      FK_sai_discente     FOREIGN KEY (id_discente)       REFERENCES Discente(id_pessoa),
    CONSTRAINT      FK_sai_curso        FOREIGN KEY (cod_curso)         REFERENCES Curso(cod_emec)
);


CREATE TABLE tranca (
    id_discente     CHAR(16),
    cod_curso       CHAR(20),
    periodo         CHAR(6),

    -- Supomos que se pode trancar mais de uma vez um mesmo curso, por isso periodo compoe a PK
    CONSTRAINT      PK_tranca               PRIMARY KEY (cod_curso, id_discente, periodo),
    CONSTRAINT      FK_tranca_discente      FOREIGN KEY (id_discente)       REFERENCES Discente(id_pessoa),
    CONSTRAINT      FK_tranca_curso         FOREIGN KEY (cod_curso)         REFERENCES Curso(cod_emec)
);
