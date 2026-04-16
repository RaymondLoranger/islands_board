# ┌────────────────────────────────────────────────────────────────────┐
# │ Based on the book "Functional Web Development" by Lance Halvorsen. │
# └────────────────────────────────────────────────────────────────────┘
defmodule Islands.Board do
  @moduledoc """
  A board struct and functions for the _Game of Islands_.

  The board struct contains the fields:

    - `islands`
    - `misses`

  representing the properties of a board in the _Game of Islands_.

  ##### Based on the book [Functional Web Development](https://pragprog.com/titles/lhelph/functional-web-development-with-elixir-otp-and-phoenix/) by Lance Halvorsen.
  """

  alias __MODULE__
  alias __MODULE__.Response
  alias Islands.{Coord, Island}

  @island_types [:atoll, :dot, :l_shape, :s_shape, :square]

  @derive JSON.Encoder
  @enforce_keys [:islands, :misses]
  defstruct [:islands, :misses]

  @typedoc "A map assigning islands to their island types"
  @type islands :: %{Island.type() => Island.t()}
  @typedoc "A board struct for the Game of Islands"
  @type t :: %Board{islands: islands, misses: Island.coords()}

  @doc """
  Returns an empty board struct.
  """
  @dialyzer {:no_opaque, [new: 0]}
  @spec new :: t
  def new, do: %Board{islands: %{}, misses: MapSet.new()}

  @doc """
  Positions `island` on `board` and returns an updated `board` or
  `{:error, reason}` if `island` overlaps another island on `board`.
  """
  @spec position_island(t, Island.t()) :: t | {:error, atom}
  def position_island(%Board{} = board, %Island{} = island) do
    if overlaps_existing_islands?(island, board.islands),
      do: {:error, :overlapping_island},
      else: put_in(board.islands[island.type], island)
  end

  @doc """
  Checks if all islands have been positioned on `board`.
  """
  @spec all_islands_positioned?(t) :: boolean
  def all_islands_positioned?(%Board{} = board) do
    Enum.all?(@island_types, &Map.has_key?(board.islands, &1))
  end

  @doc """
  Checks if `guess` hitting any island on `board` and returns a response tuple.
  """
  @spec guess(t, Coord.t()) :: Response.t()
  def guess(%Board{} = board, %Coord{} = guess) do
    Response.check_all_islands(board, guess) |> Response.full_response(board)
  end

  @doc """
  Returns a list of island types for forested islands.
  """
  @spec forested_types(t) :: [Island.type()]
  def forested_types(%Board{islands: islands} = _board) do
    islands
    |> Map.values()
    |> Enum.filter(&Island.forested?/1)
    |> Enum.map(& &1.type)
  end

  @doc """
  Returns `board`'s total number of hits.
  """
  @spec hits(t) :: non_neg_integer
  def hits(%Board{islands: islands} = _board) do
    islands
    |> Map.values()
    |> Enum.map(&MapSet.size(&1.hits))
    |> Enum.sum()
  end

  @doc """
  Returns `board`'s total number of misses.
  """
  @spec misses(t) :: non_neg_integer
  def misses(%Board{misses: misses} = _board), do: MapSet.size(misses)

  @doc """
  Returns a map assigning the CSS grid position of each island
  on `board` to its island type.
  """
  @spec grid_positions(t) :: %{Island.type() => Island.grid_position()}
  def grid_positions(%Board{islands: islands} = _board) do
    for {type, island} <- islands, into: %{} do
      {type, Island.grid_position(island)}
    end
  end

  @doc """
  Returns a map assigning the list of hit "cells" of each island
  on `board` to its island type.
  """
  @spec hit_cells(t) :: %{Island.type() => [Island.grid_cell()]}
  def hit_cells(%Board{islands: islands} = _board) do
    for {type, island} <- islands, into: %{} do
      {type, Island.hit_cells(island)}
    end
  end

  @doc """
  Returns a map assigning to :squares the list of square numbers
  from `board`'s misses.
  """
  @spec miss_squares(t) :: %{:squares => [Coord.square()]}
  def miss_squares(%Board{misses: misses} = _board) do
    %{squares: Enum.map(misses, &Coord.to_square/1)}
  end

  ## Private functions

  # We ensure we're only checking the islands that we are not replacing.
  # We don’t care about the one we're replacing because it’s going away.
  @spec overlaps_existing_islands?(Island.t(), islands) :: boolean
  defp overlaps_existing_islands?(new_island, islands) do
    Enum.any?(islands, fn {type, island} ->
      type != new_island.type and Island.overlaps?(new_island, island)
    end)
  end
end
