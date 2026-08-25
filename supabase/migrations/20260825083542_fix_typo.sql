CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id integer;
    v_household_id integer;
    v_passkey text;
BEGIN
    INSERT INTO public.user_tab (f_name, l_name, auth_id)
    VALUES (
        new.raw_user_meta_data ->> 'first_name',
        new.raw_user_meta_data ->> 'last_name',
        new.id
    )
    RETURNING user_id INTO v_user_id;

    v_passkey := 'HAUS-' || Upper(substr(md5(random()::text), 1, 6));

    INSERT INTO public.household_tab (household_name, passkey)
    VALUES (
        coalesce(new.raw_user_meta_data ->> 'last_name', 'My') || ' Library',
        v_passkey
    )
    RETURNING household_id INTO v_household_id;

    INSERT INTO public.household_member_tab (household_id, user_id, role)
    VALUES (v_household_id, v_user_id, 'admin');

    RETURN new;
END;

$$ LANGUAGE plpgsql SECURITY DEFINER;


DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
