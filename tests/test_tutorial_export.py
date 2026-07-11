from interrogation_unfold.tutorial_export import build_tutorial_export


def test_tutorial_export_preserves_shipped_graph_and_guidance():
    data = build_tutorial_export()

    assert data["benchmark"] == "interrogation-academy-tutorial"
    assert len(data["script"]) == 10
    assert len(data["tutor_lines"]) == 27
    assert len(data["episode"]["subjects"]) == 1
    assert len(data["episode"]["questions"]) == 15
    assert len(data["episode"]["answers"]) == 30
    assert data["episode"]["subjects"][0]["name"] == "Douglas Byrd"


def test_tutorial_export_resolves_dialogue_and_tutor_text():
    data = build_tutorial_export()

    assert data["episode"]["questions"][0]["text"]["key"] == "level_episode0.5"
    assert "steal bikes" in data["episode"]["questions"][0]["text"]["text"]
    assert "first drill session" in data["tutor_lines"]["tutorial.tutor1"]
