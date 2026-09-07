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

--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: device_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.device_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token character varying NOT NULL,
    platform character varying NOT NULL,
    device_name character varying,
    active boolean DEFAULT true NOT NULL,
    last_used_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: device_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.device_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: device_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.device_tokens_id_seq OWNED BY public.device_tokens.id;


--
-- Name: dishes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dishes (
    id bigint NOT NULL,
    seller_profile_id bigint NOT NULL,
    name character varying NOT NULL,
    description text,
    base_price numeric(10,2) NOT NULL,
    dietary_tags jsonb DEFAULT '[]'::jsonb,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    favorites_count integer DEFAULT 0 NOT NULL,
    discarded_at timestamp(6) without time zone
);


--
-- Name: dishes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dishes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dishes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dishes_id_seq OWNED BY public.dishes.id;


--
-- Name: favorites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.favorites (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    favoritable_type character varying NOT NULL,
    favoritable_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: favorites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.favorites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: favorites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.favorites_id_seq OWNED BY public.favorites.id;


--
-- Name: jwt_denylists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.jwt_denylists (
    id bigint NOT NULL,
    jti character varying,
    exp timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: jwt_denylists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.jwt_denylists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jwt_denylists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.jwt_denylists_id_seq OWNED BY public.jwt_denylists.id;


--
-- Name: review_helpfuls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.review_helpfuls (
    id bigint NOT NULL,
    review_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: review_helpfuls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.review_helpfuls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: review_helpfuls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.review_helpfuls_id_seq OWNED BY public.review_helpfuls.id;


--
-- Name: reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reviews (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    seller_profile_id bigint NOT NULL,
    weekly_menu_id bigint,
    rating integer NOT NULL,
    comment text,
    encounter_date date NOT NULL,
    dish_name character varying,
    encounter_latitude numeric(10,6),
    encounter_longitude numeric(10,6),
    verified_encounter boolean DEFAULT false,
    encounter_timestamp timestamp(6) without time zone,
    flagged boolean DEFAULT false,
    flag_reason character varying,
    moderation_status character varying DEFAULT 'published'::character varying,
    moderation_note text,
    moderated_at timestamp(6) without time zone,
    moderated_by_id bigint,
    helpful_count integer DEFAULT 0,
    edit_count integer DEFAULT 0,
    last_edited_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone,
    CONSTRAINT reviews_rating_range CHECK (((rating >= 1) AND (rating <= 5)))
);


--
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: seller_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seller_profiles (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    business_name character varying NOT NULL,
    bio text,
    phone character varying,
    whatsapp character varying,
    city character varying,
    state character varying,
    operating_hours jsonb DEFAULT '{}'::jsonb,
    followers_count integer DEFAULT 0 NOT NULL,
    average_rating numeric(3,2) DEFAULT 0.0,
    reviews_count integer DEFAULT 0 NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    currently_active boolean DEFAULT false NOT NULL,
    last_active_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    current_location_id bigint,
    arrived_at timestamp(6) without time zone,
    leaving_at timestamp(6) without time zone,
    favorites_count integer DEFAULT 0 NOT NULL,
    rating_1_count integer DEFAULT 0,
    rating_2_count integer DEFAULT 0,
    rating_3_count integer DEFAULT 0,
    rating_4_count integer DEFAULT 0,
    rating_5_count integer DEFAULT 0,
    discarded_at timestamp(6) without time zone
);


--
-- Name: seller_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seller_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: seller_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.seller_profiles_id_seq OWNED BY public.seller_profiles.id;


--
-- Name: selling_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.selling_locations (
    id bigint NOT NULL,
    seller_profile_id bigint NOT NULL,
    name character varying NOT NULL,
    address text,
    latitude numeric(10,6),
    longitude numeric(10,6),
    notes text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    lonlat public.geography,
    discarded_at timestamp(6) without time zone
);


--
-- Name: selling_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.selling_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: selling_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.selling_locations_id_seq OWNED BY public.selling_locations.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    name character varying NOT NULL,
    phone character varying,
    role character varying,
    active boolean DEFAULT true,
    last_seen_at timestamp(6) without time zone,
    is_admin boolean DEFAULT false NOT NULL,
    notification_preferences jsonb DEFAULT '{"new_menus": true, "promotions": false, "order_updates": true, "seller_arrivals": true}'::jsonb NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: weekly_menu_dishes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.weekly_menu_dishes (
    id bigint NOT NULL,
    weekly_menu_id bigint NOT NULL,
    dish_id bigint NOT NULL,
    available_quantity integer NOT NULL,
    remaining_quantity integer NOT NULL,
    price_override numeric(10,2),
    display_order integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


--
-- Name: weekly_menu_dishes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.weekly_menu_dishes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: weekly_menu_dishes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.weekly_menu_dishes_id_seq OWNED BY public.weekly_menu_dishes.id;


--
-- Name: weekly_menus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.weekly_menus (
    id bigint NOT NULL,
    seller_profile_id bigint NOT NULL,
    title character varying,
    description text,
    available_from timestamp(6) without time zone NOT NULL,
    available_until timestamp(6) without time zone NOT NULL,
    active boolean DEFAULT true NOT NULL,
    total_orders_count integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone
);


--
-- Name: weekly_menus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.weekly_menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: weekly_menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.weekly_menus_id_seq OWNED BY public.weekly_menus.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: device_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.device_tokens ALTER COLUMN id SET DEFAULT nextval('public.device_tokens_id_seq'::regclass);


--
-- Name: dishes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dishes ALTER COLUMN id SET DEFAULT nextval('public.dishes_id_seq'::regclass);


--
-- Name: favorites id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorites ALTER COLUMN id SET DEFAULT nextval('public.favorites_id_seq'::regclass);


--
-- Name: jwt_denylists id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jwt_denylists ALTER COLUMN id SET DEFAULT nextval('public.jwt_denylists_id_seq'::regclass);


--
-- Name: review_helpfuls id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_helpfuls ALTER COLUMN id SET DEFAULT nextval('public.review_helpfuls_id_seq'::regclass);


--
-- Name: reviews id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);


--
-- Name: seller_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seller_profiles ALTER COLUMN id SET DEFAULT nextval('public.seller_profiles_id_seq'::regclass);


--
-- Name: selling_locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.selling_locations ALTER COLUMN id SET DEFAULT nextval('public.selling_locations_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: weekly_menu_dishes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weekly_menu_dishes ALTER COLUMN id SET DEFAULT nextval('public.weekly_menu_dishes_id_seq'::regclass);


--
-- Name: weekly_menus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weekly_menus ALTER COLUMN id SET DEFAULT nextval('public.weekly_menus_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: device_tokens device_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.device_tokens
    ADD CONSTRAINT device_tokens_pkey PRIMARY KEY (id);


--
-- Name: dishes dishes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dishes
    ADD CONSTRAINT dishes_pkey PRIMARY KEY (id);


--
-- Name: favorites favorites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_pkey PRIMARY KEY (id);


--
-- Name: jwt_denylists jwt_denylists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jwt_denylists
    ADD CONSTRAINT jwt_denylists_pkey PRIMARY KEY (id);


--
-- Name: review_helpfuls review_helpfuls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_helpfuls
    ADD CONSTRAINT review_helpfuls_pkey PRIMARY KEY (id);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: seller_profiles seller_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seller_profiles
    ADD CONSTRAINT seller_profiles_pkey PRIMARY KEY (id);


--
-- Name: selling_locations selling_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.selling_locations
    ADD CONSTRAINT selling_locations_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: weekly_menu_dishes weekly_menu_dishes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weekly_menu_dishes
    ADD CONSTRAINT weekly_menu_dishes_pkey PRIMARY KEY (id);


--
-- Name: weekly_menus weekly_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weekly_menus
    ADD CONSTRAINT weekly_menus_pkey PRIMARY KEY (id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_device_tokens_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_device_tokens_on_token ON public.device_tokens USING btree (token);


--
-- Name: index_device_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_device_tokens_on_user_id ON public.device_tokens USING btree (user_id);


--
-- Name: index_device_tokens_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_device_tokens_uniqueness ON public.device_tokens USING btree (user_id, token, platform);


--
-- Name: index_dishes_on_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dishes_on_active ON public.dishes USING btree (active);


--
-- Name: index_dishes_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dishes_on_discarded_at ON public.dishes USING btree (discarded_at);


--
-- Name: index_dishes_on_seller_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dishes_on_seller_profile_id ON public.dishes USING btree (seller_profile_id);


--
-- Name: index_dishes_on_seller_profile_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dishes_on_seller_profile_id_and_name ON public.dishes USING btree (seller_profile_id, name);


--
-- Name: index_favorites_on_favoritable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorites_on_favoritable ON public.favorites USING btree (favoritable_type, favoritable_id);


--
-- Name: index_favorites_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorites_on_user_id ON public.favorites USING btree (user_id);


--
-- Name: index_favorites_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_favorites_uniqueness ON public.favorites USING btree (user_id, favoritable_type, favoritable_id);


--
-- Name: index_jwt_denylists_on_jti; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_jwt_denylists_on_jti ON public.jwt_denylists USING btree (jti);


--
-- Name: index_review_helpfuls_on_review_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_review_helpfuls_on_review_id ON public.review_helpfuls USING btree (review_id);


--
-- Name: index_review_helpfuls_on_review_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_review_helpfuls_on_review_id_and_user_id ON public.review_helpfuls USING btree (review_id, user_id);


--
-- Name: index_review_helpfuls_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_review_helpfuls_on_user_id ON public.review_helpfuls USING btree (user_id);


--
-- Name: index_reviews_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_created_at ON public.reviews USING btree (created_at);


--
-- Name: index_reviews_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_discarded_at ON public.reviews USING btree (discarded_at);


--
-- Name: index_reviews_on_encounter_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_encounter_date ON public.reviews USING btree (encounter_date);


--
-- Name: index_reviews_on_flagged; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_flagged ON public.reviews USING btree (flagged);


--
-- Name: index_reviews_on_moderated_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_moderated_by_id ON public.reviews USING btree (moderated_by_id);


--
-- Name: index_reviews_on_moderation_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_moderation_status ON public.reviews USING btree (moderation_status);


--
-- Name: index_reviews_on_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_rating ON public.reviews USING btree (rating);


--
-- Name: index_reviews_on_seller_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_seller_profile_id ON public.reviews USING btree (seller_profile_id);


--
-- Name: index_reviews_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_user_id ON public.reviews USING btree (user_id);


--
-- Name: index_reviews_on_user_seller_date; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_reviews_on_user_seller_date ON public.reviews USING btree (user_id, seller_profile_id, encounter_date);


--
-- Name: index_reviews_on_weekly_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_weekly_menu_id ON public.reviews USING btree (weekly_menu_id);


--
-- Name: index_seller_profiles_on_arrived_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_seller_profiles_on_arrived_at ON public.seller_profiles USING btree (arrived_at);


--
-- Name: index_seller_profiles_on_average_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_seller_profiles_on_average_rating ON public.seller_profiles USING btree (average_rating);


--
-- Name: index_seller_profiles_on_city; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_seller_profiles_on_city ON public.seller_profiles USING btree (city);


--
-- Name: index_seller_profiles_on_current_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_seller_profiles_on_current_location_id ON public.seller_profiles USING btree (current_location_id);


--
-- Name: index_seller_profiles_on_currently_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_seller_profiles_on_currently_active ON public.seller_profiles USING btree (currently_active);


--
-- Name: index_seller_profiles_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_seller_profiles_on_discarded_at ON public.seller_profiles USING btree (discarded_at);


--
-- Name: index_seller_profiles_on_leaving_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_seller_profiles_on_leaving_at ON public.seller_profiles USING btree (leaving_at);


--
-- Name: index_seller_profiles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_seller_profiles_on_user_id ON public.seller_profiles USING btree (user_id);


--
-- Name: index_seller_profiles_on_verified; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_seller_profiles_on_verified ON public.seller_profiles USING btree (verified);


--
-- Name: index_selling_locations_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_selling_locations_on_discarded_at ON public.selling_locations USING btree (discarded_at);


--
-- Name: index_selling_locations_on_lonlat; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_selling_locations_on_lonlat ON public.selling_locations USING gist (lonlat);


--
-- Name: index_selling_locations_on_seller_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_selling_locations_on_seller_profile_id ON public.selling_locations USING btree (seller_profile_id);


--
-- Name: index_selling_locations_on_seller_profile_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_selling_locations_on_seller_profile_id_and_name ON public.selling_locations USING btree (seller_profile_id, name);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_role ON public.users USING btree (role);


--
-- Name: index_weekly_menu_dishes_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_weekly_menu_dishes_on_discarded_at ON public.weekly_menu_dishes USING btree (discarded_at);


--
-- Name: index_weekly_menu_dishes_on_dish_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_weekly_menu_dishes_on_dish_id ON public.weekly_menu_dishes USING btree (dish_id);


--
-- Name: index_weekly_menu_dishes_on_display_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_weekly_menu_dishes_on_display_order ON public.weekly_menu_dishes USING btree (display_order);


--
-- Name: index_weekly_menu_dishes_on_menu_and_dish_kept; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_weekly_menu_dishes_on_menu_and_dish_kept ON public.weekly_menu_dishes USING btree (weekly_menu_id, dish_id) WHERE (discarded_at IS NULL);


--
-- Name: index_weekly_menu_dishes_on_weekly_menu_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_weekly_menu_dishes_on_weekly_menu_id ON public.weekly_menu_dishes USING btree (weekly_menu_id);


--
-- Name: index_weekly_menus_on_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_weekly_menus_on_active ON public.weekly_menus USING btree (active);


--
-- Name: index_weekly_menus_on_available_from; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_weekly_menus_on_available_from ON public.weekly_menus USING btree (available_from);


--
-- Name: index_weekly_menus_on_available_until; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_weekly_menus_on_available_until ON public.weekly_menus USING btree (available_until);


--
-- Name: index_weekly_menus_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_weekly_menus_on_discarded_at ON public.weekly_menus USING btree (discarded_at);


--
-- Name: index_weekly_menus_on_seller_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_weekly_menus_on_seller_profile_id ON public.weekly_menus USING btree (seller_profile_id);


--
-- Name: index_weekly_menus_on_seller_profile_id_and_available_from; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_weekly_menus_on_seller_profile_id_and_available_from ON public.weekly_menus USING btree (seller_profile_id, available_from);


--
-- Name: weekly_menu_dishes fk_rails_0d9dce8eff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weekly_menu_dishes
    ADD CONSTRAINT fk_rails_0d9dce8eff FOREIGN KEY (weekly_menu_id) REFERENCES public.weekly_menus(id);


--
-- Name: selling_locations fk_rails_214895565d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.selling_locations
    ADD CONSTRAINT fk_rails_214895565d FOREIGN KEY (seller_profile_id) REFERENCES public.seller_profiles(id);


--
-- Name: reviews fk_rails_40b29cb69d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT fk_rails_40b29cb69d FOREIGN KEY (weekly_menu_id) REFERENCES public.weekly_menus(id);


--
-- Name: weekly_menu_dishes fk_rails_547992af4b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weekly_menu_dishes
    ADD CONSTRAINT fk_rails_547992af4b FOREIGN KEY (dish_id) REFERENCES public.dishes(id);


--
-- Name: reviews fk_rails_57ddbd8409; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT fk_rails_57ddbd8409 FOREIGN KEY (moderated_by_id) REFERENCES public.users(id);


--
-- Name: seller_profiles fk_rails_5a00a19594; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seller_profiles
    ADD CONSTRAINT fk_rails_5a00a19594 FOREIGN KEY (current_location_id) REFERENCES public.selling_locations(id);


--
-- Name: weekly_menus fk_rails_6138af5dca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weekly_menus
    ADD CONSTRAINT fk_rails_6138af5dca FOREIGN KEY (seller_profile_id) REFERENCES public.seller_profiles(id);


--
-- Name: reviews fk_rails_74a66bd6c5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT fk_rails_74a66bd6c5 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: reviews fk_rails_79c5b83ff6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT fk_rails_79c5b83ff6 FOREIGN KEY (seller_profile_id) REFERENCES public.seller_profiles(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: dishes fk_rails_a5838a861e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dishes
    ADD CONSTRAINT fk_rails_a5838a861e FOREIGN KEY (seller_profile_id) REFERENCES public.seller_profiles(id);


--
-- Name: review_helpfuls fk_rails_bb81d5269f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_helpfuls
    ADD CONSTRAINT fk_rails_bb81d5269f FOREIGN KEY (review_id) REFERENCES public.reviews(id);


--
-- Name: review_helpfuls fk_rails_c1cd5482c3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_helpfuls
    ADD CONSTRAINT fk_rails_c1cd5482c3 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: favorites fk_rails_d15744e438; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT fk_rails_d15744e438 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: device_tokens fk_rails_e99e290457; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.device_tokens
    ADD CONSTRAINT fk_rails_e99e290457 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: seller_profiles fk_rails_f41802a131; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seller_profiles
    ADD CONSTRAINT fk_rails_f41802a131 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260907234500'),
('20260907230000'),
('20251114144337'),
('20251114144317'),
('20251114144239'),
('20251114144200'),
('20251110010319'),
('20251110003649'),
('20251110002042'),
('20251109234001'),
('20251109234000'),
('20251109233018'),
('20251109000004'),
('20251109000003'),
('20251109000002'),
('20251109000001'),
('20251107212103'),
('20251107211922'),
('20251107195247'),
('20251107195055'),
('20251107195027');

