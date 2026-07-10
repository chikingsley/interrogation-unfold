import pytest

from interrogation_unfold.defold_texture import FrameRect, TextureSet, frame_rect


def test_frame_rect_converts_defold_uvs_to_top_left_crop():
    texture_set = TextureSet(
        texture="/actor.texturec",
        animations=(),
        tex_coords=(
            1 / 4096,
            1540 / 2048,
            1 / 4096,
            2047 / 2048,
            450 / 4096,
            2047 / 2048,
            450 / 4096,
            1540 / 2048,
        ),
    )

    assert frame_rect(texture_set, 0, 4096, 2048) == FrameRect(1, 1, 449, 507)


def test_frame_rect_rejects_missing_frame():
    texture_set = TextureSet(texture="/empty.texturec", animations=(), tex_coords=())

    with pytest.raises(IndexError, match="outside"):
        frame_rect(texture_set, 1, 1, 1)
