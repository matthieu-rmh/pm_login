defmodule PmLogin.Services do
  @moduledoc """
  The Services context.
  """

  import Ecto.Query, warn: false
  alias PmLogin.Repo

  alias PmLogin.Services.Company

  @doc """
  Returns the list of companies.

  ## Examples

      iex> list_companies()
      [%Company{}, ...]

  """
  def list_companies do
    Repo.all(Company)
  end

  @doc """
  Gets a single company.

  Raises `Ecto.NoResultsError` if the Company does not exist.

  ## Examples

      iex> get_company!(123)
      %Company{}

      iex> get_company!(456)
      ** (Ecto.NoResultsError)

  """
  def get_company!(id), do: Repo.get!(Company, id)

  @doc """
  Creates a company.

  ## Examples

      iex> create_company(%{field: value})
      {:ok, %Company{}}

      iex> create_company(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_company(attrs \\ %{}) do
    %Company{}
    |> Company.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a company.

  ## Examples

      iex> update_company(company, %{field: new_value})
      {:ok, %Company{}}

      iex> update_company(company, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_company(%Company{} = company, attrs) do
    company
    |> Company.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a company.

  ## Examples

      iex> delete_company(company)
      {:ok, %Company{}}

      iex> delete_company(company)
      {:error, %Ecto.Changeset{}}

  """
  def delete_company(%Company{} = company) do
    Repo.delete(company)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking company changes.

  ## Examples

      iex> change_company(company)
      %Ecto.Changeset{data: %Company{}}

  """
  def change_company(%Company{} = company, attrs \\ %{}) do
    Company.changeset(company, attrs)
  end

  alias PmLogin.Services.Software

  @doc """
  Returns the list of softwares.

  ## Examples

      iex> list_softwares()
      [%Software{}, ...]

  """
  def list_softwares do
    Repo.all(Software)
  end

  @doc """
  Gets a single software.

  Raises `Ecto.NoResultsError` if the Software does not exist.

  ## Examples

      iex> get_software!(123)
      %Software{}

      iex> get_software!(456)
      ** (Ecto.NoResultsError)

  """
  def get_software!(id), do: Repo.get!(Software, id)

  @doc """
  Creates a software.

  ## Examples

      iex> create_software(%{field: value})
      {:ok, %Software{}}

      iex> create_software(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_software(attrs \\ %{}) do
    %Software{}
    |> Software.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a software.

  ## Examples

      iex> update_software(software, %{field: new_value})
      {:ok, %Software{}}

      iex> update_software(software, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_software(%Software{} = software, attrs) do
    software
    |> Software.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a software.

  ## Examples

      iex> delete_software(software)
      {:ok, %Software{}}

      iex> delete_software(software)
      {:error, %Ecto.Changeset{}}

  """
  def delete_software(%Software{} = software) do
    Repo.delete(software)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking software changes.

  ## Examples

      iex> change_software(software)
      %Ecto.Changeset{data: %Software{}}

  """
  def change_software(%Software{} = software, attrs \\ %{}) do
    Software.changeset(software, attrs)
  end
end
