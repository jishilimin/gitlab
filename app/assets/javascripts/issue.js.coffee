#= require flash
#= require jquery.waitforimages
#= require task_list

class @Issue
  constructor: ->
    # Prevent duplicate event bindings
    @disableTaskList()
    if $('a.btn-close').length
      @initTaskList()
      @initIssueBtnEventListeners()

    @initMergeRequests()
    @initRelatedBranches()
    @initCanCreateBranch()

  initTaskList: ->
    $('.detail-page-description .js-task-list-container').taskList('enable')
    $(document).on 'tasklist:changed', '.detail-page-description .js-task-list-container', @updateTaskList

  initIssueBtnEventListeners: ->
    _this = @
    issueFailMessage = '无法更新此问题。'
    $('a.btn-close, a.btn-reopen').on 'click', (e) ->
      e.preventDefault()
      e.stopImmediatePropagation()
      $this = $(this)
      isClose = $this.hasClass('btn-close')
      shouldSubmit = $this.hasClass('btn-comment')
      if shouldSubmit
        _this.submitNoteForm($this.closest('form'))
      $this.prop('disabled', true)
      url = $this.attr('href')
      $.ajax
        type: 'PUT'
        url: url,
        error: (jqXHR, textStatus, errorThrown) ->
          issueStatus = if isClose then 'close' else 'open'
          new Flash(issueFailMessage, 'alert')
        success: (data, textStatus, jqXHR) ->
          if 'id' of data
            $(document).trigger('issuable:change');
            if isClose
              $('a.btn-close').addClass('hidden')
              $('a.btn-reopen').removeClass('hidden')
              $('div.status-box-closed').removeClass('hidden')
              $('div.status-box-open').addClass('hidden')
            else
              $('a.btn-reopen').addClass('hidden')
              $('a.btn-close').removeClass('hidden')
              $('div.status-box-closed').addClass('hidden')
              $('div.status-box-open').removeClass('hidden')
          else
            new Flash(issueFailMessage, 'alert')
          $this.prop('disabled', false)

  submitNoteForm: (form) =>
    noteText = form.find("textarea.js-note-text").val()
    if noteText.trim().length > 0
      form.submit()

  disableTaskList: ->
    $('.detail-page-description .js-task-list-container').taskList('disable')
    $(document).off 'tasklist:changed', '.detail-page-description .js-task-list-container'

  # TODO (rspeicher): Make the issue description inline-editable like a note so
  # that we can re-use its form here
  updateTaskList: ->
    patchData = {}
    patchData['issue'] = {'description': $('.js-task-list-field', this).val()}

    $.ajax
      type: 'PATCH'
      url: $('form.js-issuable-update').attr('action')
      data: patchData

  initMergeRequests: ->
    $container = $('#merge-requests')

    $.getJSON($container.data('url'))
      .error ->
        new Flash('加载引用的合并请求失败', 'alert')
      .success (data) ->
        if 'html' of data
          $container.html(data.html)

  initRelatedBranches: ->
    $container = $('#related-branches')

    $.getJSON($container.data('url'))
      .error ->
        new Flash('加载关联的分支失败', 'alert')
      .success (data) ->
        if 'html' of data
          $container.html(data.html)

  initCanCreateBranch: ->
    $container = $('div#new-branch')

    # If the user doesn't have the required permissions the container isn't
    # rendered at all.
    return if $container.length is 0

    $.getJSON($container.data('path'))
      .error ->
        $container.find('.checking').hide()
        $container.find('.unavailable').show()

        new Flash('检查能否创建新分支失败', 'alert')
      .success (data) ->
        if data.can_create_branch
          $container.find('.checking').hide()
          $container.find('.available').show()
          $container.find('a').attr('disabled', false)
        else
          $container.find('.checking').hide()
          $container.find('.unavailable').show()
