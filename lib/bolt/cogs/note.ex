defmodule Bolt.Cogs.Note do
  @moduledoc false

  alias Bolt.Converters
  alias Bolt.Helpers
  alias Bolt.ModLog
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.User

  @spec command(
          Nostrum.Struct.Message.t(),
          [String.t()]
        ) :: {:ok, Nostrum.Struct.Message.t()}
  def command(msg, [user | note_list]) do
    response =
      with {:ok, member} <- Converters.to_member(msg.guild_id, user),
           note when note != "" <- Enum.join(note_list, " "),
           infraction = %{
             type: "note",
             guild_id: msg.guild_id,
             user_id: member.user.id,
             actor_id: msg.author.id,
             reason: note
           },
           changeset <- Infraction.changeset(%Infraction{}, infraction),
           {:ok, _created_infraction} <- Repo.insert(changeset) do
        ModLog.emit(
          msg.guild_id,
          "INFRACTION_CREATE",
          "#{User.full_name(msg.author)} (`#{msg.author.id}`) added a note to" <>
            " #{User.full_name(member.user)} (`#{member.user.id}`), contents: `#{note}`"
        )

        "👌 note created for #{User.full_name(member.user)} (`#{member.user.id}`)"
      else
        "" ->
          "🚫 note may not be empty"

        {:error, reason} ->
          "🚫 error: #{Helpers.clean_content(reason)}"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
