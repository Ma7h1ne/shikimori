<template lang="pug">
  .block
    input(
      type="hidden"
      name="poll[variants_attributes][]"
      v-if="is_empty"
    )
    .b-nothing_here(
      v-if="!collection.length"
    )
      | {{ I18n.t('frontend.poll_variants.nothing_here') }}
    draggable.block(
      :options="drag_options"
      v-model="collection"
      v-if="collection.length"
    )
      .b-collection_item(
        v-for="pollVariant in collection"
      )
        .delete(
          @click="remove(pollVariant)"
        )
        .drag-handle
        .b-input
          input(
            type="text"
            name="poll[variants_attributes][][label]"
            v-model="pollVariant.label"
            :placeholder="I18n.t('frontend.poll_variants.label')"
            @keydown.enter="submit"
            @keydown.8="removeEmpty(pollVariant)"
            @keydown.esc="removeEmpty(pollVariant)"
          )

    .b-button(
      @click="add"
    ) {{ I18n.t('actions.add') }}
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import draggable from 'vuedraggable'
import delay from 'delay';

export default {
  components: { draggable },
  props: {
    resource_type: String,
    entry_type: String,
    entry_id: Number
  },
  data() {
    return {
      drag_options: {
        group: 'poll_variants',
        handle: '.drag-handle'
      }
    }
  },
  computed: {
    collection: {
      get() {
        return this.$store.state.collection
      },
      set(items) {
        this.$store.dispatch('replace', items)
      }
    },
    ...mapGetters([
      'is_empty'
    ]),
  },
  methods: {
    add() {
      this.$store.dispatch('add', { label: '' })
      this.focusLast()
    },
    submit(e) {
      if (!e.metaKey && !e.ctrlKey) {
        e.preventDefault()
        this.add()
      }
    },
    removeEmpty(pollVariant) {
      if (Object.isEmpty(pollVariant.label) && this.$store.state.collection.length > 1) {
        this.remove(pollVariant)
        this.focusLast()
      }
    },
    async focusLast() {
      // do not use this.$nextTick. it passes "backspace" event to focused input
      await delay();
      $('input', this.$el).last().focus();
    },
    ...mapActions([
      'remove'
    ])
  }
}
</script>

<style scoped lang="sass">
  .b-nothing_here
    margin-bottom: 15px

  .b-collection_item
    .delete
      top: 3px

    .drag-handle
      top: 3px
      left: 53px

    &:first-child
      margin-top: 5px

    &:first-child:last-child
      .drag-handle
        display: none

      .b-input
        margin-left: 0

    .b-input
      margin-left: 25px
</style>
