/*==============================================================*/
/* DBMS name:      ORACLE Version 11g                           */
/* Created on:     08/03/2025 06:06:31                          */
/*==============================================================*/

/*==============================================================*/
/* Table: ARMAZEM                                               */
/*==============================================================*/
create table ARMAZEM 
(
   ID_ARMAZEM           NUMBER               not null,
   LOCALIZACAO          VARCHAR2(100),
   constraint PK_ARMAZEM primary key (ID_ARMAZEM)
);

/*==============================================================*/
/* Table: COMPARTIMENTOS                                        */
/*==============================================================*/
create table COMPARTIMENTOS 
(
   ID_COMPARTIMENTO     NUMBER               not null,
   ID_PRODUTO           NUMBER,
   ID_MAQUINA           NUMBER,
   CODIGO               VARCHAR2(10),
   CAPACIDADE_MAXIMA    NUMBER,
   PRECO_COMPARTIMENTO  NUMBER,
   constraint PK_COMPARTIMENTOS primary key (ID_COMPARTIMENTO)
);


/*==============================================================*/
/* Table: DISTANCA_ARMAZEM_MAQUINA                              */
/*==============================================================*/
create table DISTANCA_ARMAZEM_MAQUINA 
(
   ID_MAQUINA           NUMBER               not null,
   ID_ARMAZEM           NUMBER               not null,
   DIST_MAQ_ARM_KM      NUMBER,
   constraint PK_DISTANCA_ARMAZEM_MAQUINA primary key (ID_MAQUINA, ID_ARMAZEM)
);


/*==============================================================*/
/* Table: DISTANCIA_MAQUINAS                                    */
/*==============================================================*/
create table DISTANCIA_MAQUINAS 
(
   MAQ_ID_MAQUINA       NUMBER               not null,
   ID_MAQUINA           NUMBER               not null,
   DIST_MAQ1_MAQ2_KM    NUMBER,
   constraint PK_DISTANCIA_MAQUINAS primary key (MAQ_ID_MAQUINA, ID_MAQUINA)
);


/*==============================================================*/
/* Table: FUNCIONARIOS                                          */
/*==============================================================*/
create table FUNCIONARIOS 
(
   ID_FUNCIONARIO       NUMBER               not null,
   ID_ARMAZEM           NUMBER,
   NIF                  VARCHAR2(9),
   NOME_FUNCIONARIO     VARCHAR2(50),
   constraint PK_FUNCIONARIOS primary key (ID_FUNCIONARIO)
);


/*==============================================================*/
/* Table: HISTORICO_ESTADOS                                     */
/*==============================================================*/
create table HISTORICO_ESTADOS 
(
   ID_ESTADO            NUMBER               not null,
   ID_MAQUINA           NUMBER,
   DATA_HORA_ESTADO     DATE,
   ESTADO               VARCHAR2(30),
   constraint PK_HISTORICO_ESTADOS primary key (ID_ESTADO)
);


/*==============================================================*/
/* Table: MANUTENCAO                                            */
/*==============================================================*/
create table MANUTENCAO 
(
   ID_MANUTENCAO        NUMBER               not null,
   ID_VISITA            NUMBER,
   ID_MAQUINA           NUMBER,
   DATA_HORA_MANUTENCAO DATE,
   TIPO_MANUTENCAO      VARCHAR2(100),
   constraint PK_MANUTENCAO primary key (ID_MANUTENCAO)
);


/*==============================================================*/
/* Table: MAQUINAS                                              */
/*==============================================================*/
create table MAQUINAS 
(
   ID_MAQUINA           NUMBER               not null,
   LOCALIZACAO_         VARCHAR2(100),
   ESTADO_MAQUINA       VARCHAR2(30),
   constraint PK_MAQUINAS primary key (ID_MAQUINA)
);

/*==============================================================*/
/* Table: PRODUTOS                                              */
/*==============================================================*/
create table PRODUTOS 
(
   ID_PRODUTO           NUMBER               not null,
   NOME_PRODUTO         VARCHAR2(50),
   TIPO                 VARCHAR2(50),
   REFERENCIA           VARCHAR2(20),
   PRECO_PRODUTO        NUMBER,
   constraint PK_PRODUTOS primary key (ID_PRODUTO)
);

/*==============================================================*/
/* Table: REABASTECIMENTOS                                      */
/*==============================================================*/
create table REABASTECIMENTOS 
(
   ID_REABASTECIMENTO   NUMBER               not null,
   ID_VISITA            NUMBER,
   ID_COMPARTIMENTO     NUMBER,
   ID_PRODUTO           NUMBER,
   QUANTIDADE           NUMBER,
   DATA_HORA_REABASTECIMENTO DATE,
   constraint PK_REABASTECIMENTOS primary key (ID_REABASTECIMENTO)
);

/*==============================================================*/
/* Table: ROTAS                                                 */
/*==============================================================*/
create table ROTAS 
(
   ID_ROTA              NUMBER               not null,
   NOME_ROTA            VARCHAR2(50),
   constraint PK_ROTAS primary key (ID_ROTA)
);

/*==============================================================*/
/* Table: ROTASDEFENIDAS                                        */
/*==============================================================*/
create table ROTASDEFENIDAS 
(
   ID_MAQUINA           NUMBER               not null,
   ID_ROTA              NUMBER               not null,
   ORDEM                NUMBER,
   constraint PK_ROTASDEFENIDAS primary key (ID_MAQUINA, ID_ROTA)
);


/*==============================================================*/
/* Table: RUPTURAS                                              */
/*==============================================================*/
create table RUPTURAS 
(
   ID_RUPTURA           NUMBER               not null,
   ID_COMPARTIMENTO     NUMBER,
   ID_PRODUTO           NUMBER,
   DATA_HORA_RUPTURA    DATE,
   constraint PK_RUPTURAS primary key (ID_RUPTURA)
);


/*==============================================================*/
/* Table: STOCK                                                 */
/*==============================================================*/
create table STOCK 
(
   ID_PRODUTO           NUMBER               not null,
   ID_ARMAZEM           NUMBER               not null,
   QUANTIDADE_EM_STOCK  NUMBER,
   constraint PK_STOCK primary key (ID_PRODUTO, ID_ARMAZEM)
);



/*==============================================================*/
/* Table: VEICULOS                                              */
/*==============================================================*/
create table VEICULOS 
(
   ID_VEICULO           NUMBER               not null,
   ID_ARMAZEM           NUMBER,
   MATRICULA            VARCHAR2(8),
   MARCA                VARCHAR2(30),
   AUTONOMIA_KM         NUMBER,
   MODELO               VARCHAR2(30),
   CAPACIDADE_CARGA_VEICULO NUMBER,
   constraint PK_VEICULOS primary key (ID_VEICULO)
);


/*==============================================================*/
/* Table: VENDAS                                                */
/*==============================================================*/
create table VENDAS 
(
   ID_VENDA             NUMBER               not null,
   ID_COMPARTIMENTO     NUMBER,
   ID_PRODUTO           NUMBER,
   DATA_HORA_VENDA      DATE,
   METODO_PAGAMENTO     VARCHAR2(50),
   VALOR_PAGO           NUMBER,
   CODIGO_INSERIDO      VARCHAR2(10),
   constraint PK_VENDAS primary key (ID_VENDA)
);


/*==============================================================*/
/* Table: VIAGENS                                               */
/*==============================================================*/
create table VIAGENS 
(
   ID_VIAGEM            NUMBER               not null,
   ID_ROTA              NUMBER,
   ID_VEICULO           NUMBER,
   ID_FUNCIONARIO       NUMBER,
   DATA_INICIO_VIAGEM   DATE,
   DISTANCIA_PERCORRIDA NUMBER,
   constraint PK_VIAGENS primary key (ID_VIAGEM)
);


/*==============================================================*/
/* Table: VISITAS                                               */
/*==============================================================*/
create table VISITAS 
(
   ID_VISITA            NUMBER               not null,
   ID_VIAGEM            NUMBER,
   ID_MAQUINA           NUMBER,
   DATA_HORA_CHEGADA    DATE,
   DATA_HORA_SAIDA      DATE,
   constraint PK_VISITAS primary key (ID_VISITA)
);



alter table COMPARTIMENTOS
   add constraint FK_COMPARTI_PRODUTO_C_PRODUTOS foreign key (ID_PRODUTO)
      references PRODUTOS (ID_PRODUTO);

alter table COMPARTIMENTOS
   add constraint FK_COMPARTI_RELATIONS_MAQUINAS foreign key (ID_MAQUINA)
      references MAQUINAS (ID_MAQUINA);

alter table DISTANCA_ARMAZEM_MAQUINA
   add constraint FK_DISTANCA_ARMAZEM_I_ARMAZEM foreign key (ID_ARMAZEM)
      references ARMAZEM (ID_ARMAZEM);

alter table DISTANCA_ARMAZEM_MAQUINA
   add constraint FK_DISTANCA_MAQUINA_I_MAQUINAS foreign key (ID_MAQUINA)
      references MAQUINAS (ID_MAQUINA);

alter table DISTANCIA_MAQUINAS
   add constraint FK_DISTANCI_MAQUINA_1_MAQUINAS foreign key (MAQ_ID_MAQUINA)
      references MAQUINAS (ID_MAQUINA);

alter table DISTANCIA_MAQUINAS
   add constraint FK_DISTANCI_MAQUINA_2_MAQUINAS foreign key (ID_MAQUINA)
      references MAQUINAS (ID_MAQUINA);

alter table FUNCIONARIOS
   add constraint FK_FUNCIONA_ARMAZEM_F_ARMAZEM foreign key (ID_ARMAZEM)
      references ARMAZEM (ID_ARMAZEM);

alter table HISTORICO_ESTADOS
   add constraint FK_HISTORIC_HISTORICO_MAQUINAS foreign key (ID_MAQUINA)
      references MAQUINAS (ID_MAQUINA);

alter table MANUTENCAO
   add constraint FK_MANUTENC_MANUTENCA_MAQUINAS foreign key (ID_MAQUINA)
      references MAQUINAS (ID_MAQUINA);

alter table MANUTENCAO
   add constraint FK_MANUTENC_VISITAS_M_VISITAS foreign key (ID_VISITA)
      references VISITAS (ID_VISITA);

alter table REABASTECIMENTOS
   add constraint FK_REABASTE_REABASTEC_COMPARTI foreign key (ID_COMPARTIMENTO)
      references COMPARTIMENTOS (ID_COMPARTIMENTO);

alter table REABASTECIMENTOS
   add constraint FK_REABASTE_REABASTEC_PRODUTOS foreign key (ID_PRODUTO)
      references PRODUTOS (ID_PRODUTO);

alter table REABASTECIMENTOS
   add constraint FK_REABASTE_VISITAS_R_VISITAS foreign key (ID_VISITA)
      references VISITAS (ID_VISITA);

alter table ROTASDEFENIDAS
   add constraint FK_ROTASDEF_MAQUINAS__MAQUINAS foreign key (ID_MAQUINA)
      references MAQUINAS (ID_MAQUINA);

alter table ROTASDEFENIDAS
   add constraint FK_ROTASDEF_ROTAS_ID_ROTAS foreign key (ID_ROTA)
      references ROTAS (ID_ROTA);

alter table RUPTURAS
   add constraint FK_RUPTURAS_RUPTURAS__COMPARTI foreign key (ID_COMPARTIMENTO)
      references COMPARTIMENTOS (ID_COMPARTIMENTO);

alter table RUPTURAS
   add constraint FK_RUPTURAS_RUPTURAS__PRODUTOS foreign key (ID_PRODUTO)
      references PRODUTOS (ID_PRODUTO);

alter table STOCK
   add constraint FK_STOCK_STOCK_ARM_ARMAZEM foreign key (ID_ARMAZEM)
      references ARMAZEM (ID_ARMAZEM);

alter table STOCK
   add constraint FK_STOCK_STOCK_PRO_PRODUTOS foreign key (ID_PRODUTO)
      references PRODUTOS (ID_PRODUTO);

alter table VEICULOS
   add constraint FK_VEICULOS_RELATIONS_ARMAZEM foreign key (ID_ARMAZEM)
      references ARMAZEM (ID_ARMAZEM);

alter table VENDAS
   add constraint FK_VENDAS_VENDAS_CO_COMPARTI foreign key (ID_COMPARTIMENTO)
      references COMPARTIMENTOS (ID_COMPARTIMENTO);

alter table VENDAS
   add constraint FK_VENDAS_VENDAS_PR_PRODUTOS foreign key (ID_PRODUTO)
      references PRODUTOS (ID_PRODUTO);

alter table VIAGENS
   add constraint FK_VIAGENS_ROTAS_VIA_ROTAS foreign key (ID_ROTA)
      references ROTAS (ID_ROTA);

alter table VIAGENS
   add constraint FK_VIAGENS_VIAGENS_F_FUNCIONA foreign key (ID_FUNCIONARIO)
      references FUNCIONARIOS (ID_FUNCIONARIO);

alter table VIAGENS
   add constraint FK_VIAGENS_VIAGENS_V_VEICULOS foreign key (ID_VEICULO)
      references VEICULOS (ID_VEICULO);

alter table VISITAS
   add constraint FK_VISITAS_VISITAS_M_MAQUINAS foreign key (ID_MAQUINA)
      references MAQUINAS (ID_MAQUINA);

alter table VISITAS
   add constraint FK_VISITAS_VISITAS_V_VIAGENS foreign key (ID_VIAGEM)
      references VIAGENS (ID_VIAGEM);

