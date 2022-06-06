--
-- PostgreSQL database dump
--

-- Dumped from database version 12.10 (Ubuntu 12.10-0ubuntu0.20.04.1)
-- Dumped by pg_dump version 12.10 (Ubuntu 12.10-0ubuntu0.20.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: colors; Type: TABLE; Schema: public; Owner: zmorgan
--

CREATE TABLE public.colors (
    id integer NOT NULL,
    inventory_id integer NOT NULL,
    line_id integer NOT NULL,
    depth character varying(2) NOT NULL,
    tone character varying(2) NOT NULL,
    count integer NOT NULL,
    CONSTRAINT colors_count_check CHECK ((count >= 0))
);


ALTER TABLE public.colors OWNER TO zmorgan;

--
-- Name: colors_id_seq; Type: SEQUENCE; Schema: public; Owner: zmorgan
--

CREATE SEQUENCE public.colors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.colors_id_seq OWNER TO zmorgan;

--
-- Name: colors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: zmorgan
--

ALTER SEQUENCE public.colors_id_seq OWNED BY public.colors.id;


--
-- Name: colors id; Type: DEFAULT; Schema: public; Owner: zmorgan
--

ALTER TABLE ONLY public.colors ALTER COLUMN id SET DEFAULT nextval('public.colors_id_seq'::regclass);


--
-- Data for Name: colors; Type: TABLE DATA; Schema: public; Owner: zmorgan
--

COPY public.colors (id, inventory_id, line_id, depth, tone, count) FROM stdin;
51	40	44	1	5	4
52	40	44	2	3	3
53	40	44	4	6	7
54	40	44	6	2	1
55	40	44	7	1	1
56	40	44	2	11	2
57	40	44	11	7	3
58	40	44	6	5	4
59	40	44	4	3	1
60	40	44	9	4	4
61	40	44	4	22	1
62	40	45	3	5	1
63	40	45	6	3	7
64	40	45	3	9	4
\.


--
-- Name: colors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: zmorgan
--

SELECT pg_catalog.setval('public.colors_id_seq', 64, true);


--
-- Name: colors colors_pkey; Type: CONSTRAINT; Schema: public; Owner: zmorgan
--

ALTER TABLE ONLY public.colors
    ADD CONSTRAINT colors_pkey PRIMARY KEY (id);


--
-- Name: colors colors_inventory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: zmorgan
--

ALTER TABLE ONLY public.colors
    ADD CONSTRAINT colors_inventory_id_fkey FOREIGN KEY (inventory_id) REFERENCES public.inventories(id) ON DELETE CASCADE;


--
-- Name: colors colors_line_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: zmorgan
--

ALTER TABLE ONLY public.colors
    ADD CONSTRAINT colors_line_id_fkey FOREIGN KEY (line_id) REFERENCES public.lines(id);


--
-- PostgreSQL database dump complete
--

