from interrogation_unfold.corpus import episode_inventory, fuior_inventory, lua_inventory


def test_episode_inventory_current_corpus_counts():
    _rows, totals = episode_inventory()

    assert totals["files"] == 46
    assert totals["subjects"] == 70
    assert totals["questions"] == 5031
    assert totals["answers"] == 7776
    assert totals["hints"] == 93


def test_fuior_inventory_current_corpus_counts():
    inventory = fuior_inventory()

    assert inventory["files_by_folder"][:4] == [
        ("chapter2", 20),
        ("(root)", 17),
        ("chapter3", 14),
        ("chapter1", 12),
    ]


def test_lua_inventory_keeps_major_subsystems_visible():
    by_path = {path: file_count for path, file_count, _line_count in lua_inventory()}

    assert by_path["corpus/main"] == 184
    assert by_path["corpus/level"] == 46
    assert by_path["corpus/campaign"] == 79
