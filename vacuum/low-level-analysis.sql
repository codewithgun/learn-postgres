SELECT t_xmin,
    t_xmax,
    tuple_data_split(
        'public.student'::regclass,
        t_data,
        t_infomask,
        t_infomask2,
        t_bits
    )
FROM heap_page_items(get_raw_page('public.student', 0));