defmodule Islands.BoardTest do
  use ExUnit.Case, async: true

  alias Islands.{Board, Coord, Island}

  doctest Board

  setup_all do
    # See Player's Board in Functional Web Development on page 13...
    {:ok, atoll_origin} = Coord.new(1, 1)
    {:ok, dot_origin} = Coord.new(9, 9)
    {:ok, l_shape_origin} = Coord.new(3, 7)
    {:ok, s_shape_origin} = Coord.new(6, 2)
    {:ok, square_origin} = Coord.new(9, 5)
    {:ok, dot_overlap_origin} = Coord.new(3, 2)

    {:ok, atoll} = Island.new(:atoll, atoll_origin)
    {:ok, dot} = Island.new(:dot, dot_origin)
    {:ok, l_shape} = Island.new(:l_shape, l_shape_origin)
    {:ok, s_shape} = Island.new(:s_shape, s_shape_origin)
    {:ok, square} = Island.new(:square, square_origin)
    {:ok, dot_overlap} = Island.new(:dot, dot_overlap_origin)

    grid_positions = %{
      atoll: %{gridColumnStart: 1, gridRowStart: 1},
      dot: %{gridColumnStart: 9, gridRowStart: 9},
      l_shape: %{gridColumnStart: 7, gridRowStart: 3},
      s_shape: %{gridColumnStart: 2, gridRowStart: 6},
      square: %{gridColumnStart: 5, gridRowStart: 9}
    }

    {:ok, atoll_b1} = Coord.new(1, 2)
    {:ok, atoll_b2} = Coord.new(2, 2)
    {:ok, atoll_b3} = Coord.new(3, 2)
    atoll_hits = %{b1: atoll_b1, b2: atoll_b2, b3: atoll_b3}

    {:ok, l_shape_a3} = Coord.new(5, 7)
    l_shape_hits = %{a3: l_shape_a3}

    {:ok, dot_a1} = Coord.new(9, 9)
    dot_hits = %{a1: dot_a1}

    hits = %{atoll: atoll_hits, l_shape: l_shape_hits, dot: dot_hits}

    {:ok, square_13} = Coord.new(2, 3)
    {:ok, square_99} = Coord.new(10, 9)
    misses = %{square_13: square_13, square_99: square_99}

    incomplete =
      Board.new()
      |> Board.position_island(square)
      |> Board.position_island(dot)

    complete =
      incomplete
      |> Board.position_island(l_shape)
      |> Board.position_island(s_shape)
      |> Board.position_island(atoll)

    origins = %{
      atoll: atoll_origin,
      dot: dot_origin,
      l_shape: l_shape_origin,
      s_shape: s_shape_origin,
      square: square_origin,
      dot_overlap: dot_overlap_origin
    }

    islands = %{
      atoll: atoll,
      dot: dot,
      l_shape: l_shape,
      s_shape: s_shape,
      square: square,
      dot_overlap: dot_overlap
    }

    boards = %{incomplete: incomplete, complete: complete}

    encoded =
      ~s<{"islands":{"dot":{"type":"dot","origin":{"row":9,"col":9},"coords":[{"row":9,"col":9}],"hits":[]},"square":{"type":"square","origin":{"row":9,"col":5},"coords":[{"row":9,"col":5},{"row":9,"col":6},{"row":10,"col":5},{"row":10,"col":6}],"hits":[]}},"misses":[]}>

    decoded = %{
      "islands" => %{
        "dot" => %{
          "coords" => [%{"col" => 9, "row" => 9}],
          "hits" => [],
          "type" => "dot",
          "origin" => %{"col" => 9, "row" => 9}
        },
        "square" => %{
          "coords" => [
            %{"col" => 5, "row" => 9},
            %{"col" => 6, "row" => 9},
            %{"col" => 5, "row" => 10},
            %{"col" => 6, "row" => 10}
          ],
          "hits" => [],
          "type" => "square",
          "origin" => %{"col" => 5, "row" => 9}
        }
      },
      "misses" => []
    }

    %{
      json: %{encoded: encoded, decoded: decoded},
      origins: origins,
      islands: islands,
      boards: boards,
      grid_positions: grid_positions,
      hits: hits,
      misses: misses
    }
  end

  describe "A board struct" do
    test "can be encoded by JSON", %{boards: boards, json: json} do
      assert JSON.encode!(boards.incomplete) == json.encoded
      assert JSON.decode!(json.encoded) == json.decoded
    end
  end

  describe "Board.position_island/2" do
    test "returns a board struct given valid args", %{islands: islands} do
      square = islands.square
      board = Board.new() |> Board.position_island(square)
      assert %Board{} = board
      assert %{square: %Island{} = ^square} = board.islands
    end

    test "returns {:error, reason} if islands overlap", %{islands: islands} do
      atoll = islands.atoll
      dot_overlap = islands.dot_overlap
      %Board{} = board = Board.new() |> Board.position_island(atoll)

      assert Board.position_island(board, dot_overlap) ==
               {:error, :overlapping_island}
    end
  end

  describe "Board.all_islands_positioned?/1" do
    test "asserts all islands positioned", %{boards: boards} do
      assert Board.all_islands_positioned?(boards.complete)
    end

    test "refutes all islands positioned", %{boards: boards} do
      refute Board.all_islands_positioned?(boards.incomplete)
    end
  end

  describe "Board.guess/2" do
    test "detects a hit guess", %{origins: origins, boards: boards} do
      assert {:hit, :dot, :no_win, %Board{}} =
               Board.guess(boards.complete, origins.dot)
    end

    test "detects a miss guess", %{origins: origins, boards: boards} do
      assert {:miss, :none, :no_win, %Board{}} =
               Board.guess(boards.complete, origins.s_shape)
    end

    test "detects a win guess", %{origins: origins, boards: boards} do
      square = boards.incomplete.islands.square
      square = put_in(square.hits, square.coords)

      assert {:hit, :dot, :win, %Board{}} =
               boards.incomplete
               |> Board.position_island(square)
               |> Board.guess(origins.dot)
    end
  end

  describe "Board.forested_types/1" do
    test "lists the island types of forested islands", %{boards: boards} do
      atoll = boards.complete.islands.atoll
      atoll = put_in(atoll.hits, atoll.coords)
      dot = boards.complete.islands.dot
      dot = put_in(dot.hits, dot.coords)

      board =
        boards.complete
        |> Board.position_island(atoll)
        |> Board.position_island(dot)

      assert Board.forested_types(board) |> Enum.sort() == [:atoll, :dot]
    end
  end

  describe "Board.grid_positions/1" do
    test "returns a map of grid positions", %{
      grid_positions: grid_positions,
      boards: boards
    } do
      assert Board.grid_positions(boards.complete) == grid_positions
    end
  end

  describe "Board.hit_cells/1" do
    test "returns a map of hit cells", %{boards: boards, hits: hits} do
      board = boards.complete
      {:hit, :none, :no_win, board} = Board.guess(board, hits.atoll.b1)
      {:hit, :none, :no_win, board} = Board.guess(board, hits.atoll.b2)
      {:hit, :none, :no_win, board} = Board.guess(board, hits.atoll.b3)
      {:hit, :dot, :no_win, board} = Board.guess(board, hits.dot.a1)
      {:hit, :none, :no_win, board} = Board.guess(board, hits.l_shape.a3)

      assert Board.hit_cells(board) == %{
               atoll: ["b1", "b2", "b3"],
               dot: ["a1"],
               l_shape: ["a3"],
               s_shape: [],
               square: []
             }
    end
  end

  describe "Board.miss_squares/1" do
    test "returns a map of square numbers", %{boards: boards, misses: misses} do
      board = boards.complete
      {:miss, :none, :no_win, board} = Board.guess(board, misses.square_13)
      {:miss, :none, :no_win, board} = Board.guess(board, misses.square_99)

      assert Board.miss_squares(board) in [
               %{squares: [13, 99]},
               %{squares: [99, 13]}
             ]
    end
  end
end
